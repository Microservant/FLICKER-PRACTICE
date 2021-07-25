
;;; gist.el --- Emacs integration for gist.github.com

;; Author: Yann Hodique <yann.hodique@gmail.com>
;; Original Author: Christian Neukirchen <chneukirchen@gmail.com>
;; Contributors: Chris Wanstrath <chris@ozmm.org>
;;               Will Farrington <wcfarrington@gmail.com>
;;               Michael Ivey
;;               Phil Hagelberg
;;               Dan McKinley
;;               Marcelo Muñoz Araya <ma.munoz.araya@gmail.com>
;; Version: 1.4.0
;; Package-Requires: ((emacs "24.1") (gh "0.10.0"))
;; Keywords: tools
;; Homepage: https://github.com/defunkt/gist.el

;; This file is NOT part of GNU Emacs.

;; This is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 2, or (at your option) any later
;; version.
;;
;; This is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
;; FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
;; for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
;; MA 02111-1307, USA.

;;; Commentary:

;; An Emacs interface for managing gists (http://gist.github.com).

;;; Code:

(eval-when-compile
  (require 'cl))

(require 'eieio)
(require 'eieio-base)
(require 'timezone)

(require 'gh-api)
(require 'gh-gist)
(require 'gh-profile)

(require 'tabulated-list)

(defgroup gist nil
  "Interface to GitHub's Gist."
  :group 'applications)

(defcustom gist-list-format '((id "Id" 10 nil identity)
                              (created "Created" 20 nil "%D %R")
                              (visibility "Visibility" 10 nil
                                          (lambda (public)
                                            (or (and public "public")
                                                "private")))
                              (description "Description" 0 nil identity))
  "Format for gist list."
  :type '(alist :key-type
          (choice
           (const :tag "Id" id)
           (const :tag "Creation date" created)
           (const :tag "Visibility" visibility)
           (const :tag "Description" description)
           (const :tag "Files" files))
          :value-type
          (list
           (string :tag "Label")
           (integer :tag "Field length")
           (boolean :tag "Sortable")
           (choice
            (string :tag "Format")
            (function :tag "Formatter"))))
  :group 'gist)

(defcustom gist-view-gist nil
  "If non-nil, view gists with `browse-url' after posting."
  :type 'boolean
  :group 'gist)

(defcustom gist-multiple-files-mark "+"
  "Symbol to use to indicate gists with multiple files."
  :type 'string
  :group 'gist)

(defcustom gist-ask-for-description nil
  "If non-nil, prompt for description before submitting gist."
  :type 'boolean
  :group 'gist)

(defcustom gist-ask-for-filename nil
  "If non-nil, prompt for change default file name before submitting gist."
  :type 'boolean
  :group 'gist)

(defcustom gist-created-fmt "Paste created: %s"
  "Format for the message that gets shown upon successful gist
creation.  Must contain a single %s for the location of the newly
created gist."
  :type 'string
  :group 'gist)

(defcustom gist-supported-modes-alist '((action-script-mode . "as")
                                        (c-mode . "c")
                                        (c++-mode . "cpp")
                                        (clojure-mode . "clj")
                                        (common-lisp-mode . "lisp")
                                        (css-mode . "css")
                                        (diff-mode . "diff")
                                        (emacs-lisp-mode . "el")
                                        (lisp-interaction-mode . "el")
                                        (erlang-mode . "erl")
                                        (haskell-mode . "hs")
                                        (html-mode . "html")
                                        (io-mode . "io")
                                        (java-mode . "java")
                                        (javascript-mode . "js")
                                        (jde-mode . "java")
                                        (js2-mode . "js")
                                        (lua-mode . "lua")
                                        (ocaml-mode . "ml")
                                        (objective-c-mode . "m")
                                        (perl-mode . "pl")
                                        (php-mode . "php")
                                        (python-mode . "py")
                                        (ruby-mode . "rb")
                                        (text-mode . "txt")
                                        (scala-mode . "scala")
                                        (sql-mode . "sql")
                                        (scheme-mode . "scm")
                                        (smalltalk-mode . "st")
                                        (sh-mode . "sh")
                                        (tcl-mode . "tcl")
                                        (tex-mode . "tex")
                                        (xml-mode . "xml"))
  "Mapping between major-modes and file extensions.
Used to generate filenames for created gists, and to select
appropriate modes from fetched gist files (based on filenames)."
  :type '(alist :key-type   (symbol :tag "Mode")
                :value-type (string :tag "Extension")))

(defvar gist-list-db nil)
(unless (hash-table-p gist-list-db)
  (setq gist-list-db (make-hash-table :test 'equal)))

(defvar gist-list-db-by-user nil)
(unless (hash-table-p gist-list-db-by-user)
  (setq gist-list-db-by-user (make-hash-table :test 'equal)))

(defvar gist-list-limits nil)

(defvar gist-id nil)
(make-variable-buffer-local 'gist-id)

(defvar gist-filename nil)
(make-variable-buffer-local 'gist-filename)

(defvar gist-user-history nil "History list for gist-list-user.")

(defvar gist-list-buffer-user nil "Username for this gist buffer.")
(make-variable-buffer-local 'gist-list-buffer-user)
(put 'gist-list-buffer-user 'permanent-local t)

(defun gist-get-api (&optional sync)
  (let ((gh-profile-current-profile
         (or gh-profile-current-profile (gh-profile-completing-read))))
    (make-instance 'gh-gist-api :sync sync :cache t :num-retries 1)))

(defun gist-internal-new (files &optional private description callback)
  (let* ((api (gist-get-api))
         (gist (make-instance 'gh-gist-gist-stub
                              :public (or (not private) json-false)
                              :description (or description "")
                              :files files))
         (resp (gh-gist-new api gist)))
    (gh-url-add-response-callback
     resp
     (lexical-let ((profile (oref api :profile))
                   (cb callback))
       (lambda (gist)
         (let ((gh-profile-current-profile profile))
           (funcall (or cb 'gist-created-callback) gist)))))))

(defun gist-ask-for-description-maybe ()
  (when gist-ask-for-description
    (read-from-minibuffer "Gist description: ")))

(defun gist-ask-for-filename-maybe (fname)
  (if gist-ask-for-filename
      (read-string (format "File name (%s): " fname) nil nil fname)
    fname))

;;;###autoload
(defun gist-region (begin end &optional private callback)
  "Post the current region as a new paste at gist.github.com
Copies the URL into the kill ring.

With a prefix argument, makes a private paste."
  (interactive "r\nP")
  (let* ((file (or (buffer-file-name) (buffer-name)))
         (name (file-name-nondirectory file))
         (ext (or (cdr (assoc major-mode gist-supported-modes-alist))
                  (file-name-extension file)
                  "txt"))
         (proposal-fname (concat (file-name-sans-extension name) "." ext))
         (fname (gist-ask-for-filename-maybe proposal-fname))
         (files (list
                 (make-instance 'gh-gist-gist-file
                                :filename fname
                                :content (buffer-substring begin end)))))
    (gist-internal-new files private
                       (gist-ask-for-description-maybe) callback)))

(defun gist-files (filenames &optional private callback)
  (let ((files nil))
    (dolist (f filenames)
      (with-temp-buffer
        (insert-file-contents f)
        (let ((name (file-name-nondirectory f)))
          (push (make-instance 'gh-gist-gist-file :filename name :content (buffer-string))
                files))))
    (gist-internal-new files private
                       (gist-ask-for-description-maybe) callback)))

(defun gist-created-callback (gist)
  (let ((location (oref gist :html-url)))
    (gist-list-reload 'current-user t)
    (message gist-created-fmt location)
    (when gist-view-gist
      (browse-url location))
    (kill-new location)))

;;;###autoload
(defun gist-region-private (begin end)
  "Post the current region as a new private paste at gist.github.com
Copies the URL into the kill ring."
  (interactive "r")
  (gist-region begin end t))

;;;###autoload
(defun gist-buffer (&optional private)
  "Post the current buffer as a new paste at gist.github.com.
Copies the URL into the kill ring.

With a prefix argument, makes a private paste."
  (interactive "P")
  (gist-region (point-min) (point-max) private))

;;;###autoload
(defun gist-buffer-private ()
  "Post the current buffer as a new private paste at gist.github.com.
Copies the URL into the kill ring."
  (interactive)
  (gist-region-private (point-min) (point-max)))

;;;###autoload
(defun gist-region-or-buffer (&optional private)
  "Post either the current region, or if mark is not set, the
  current buffer as a new paste at gist.github.com

Copies the URL into the kill ring.

With a prefix argument, makes a private paste."
  (interactive "P")
  (if (region-active-p)
      (gist-region (point) (mark) private)
    (gist-buffer private)))

;;;###autoload
(defun gist-region-or-buffer-private ()
  "Post either the current region, or if mark is not set, the
  current buffer as a new private paste at gist.github.com

Copies the URL into the kill ring."
  (interactive)
  (if (region-active-p)
      (gist-region-private (point) (mark))
    (gist-buffer-private)))

;;;###autoload
(defun gist-list-user (username &optional force-reload background)
  "Displays a list of a user's gists in a new buffer.  When called from
  a program, pass 'current-user as the username to view the user's own
  gists, or nil for the username and a non-nil value for force-reload to
  reload the gists for the current buffer."
  (interactive
   (let ((username (read-from-minibuffer "GitHub user: " nil nil nil
                                          'gist-user-history))
         (force-reload (equal current-prefix-arg '(4))))
     (list username force-reload)))
  ;; if buffer exists, it contains the current gh profile
  (let* ((gh-profile-current-profile (or gh-profile-current-profile
                                         (gh-profile-completing-read)))
         (bufname (if (null username)
                      (if (not (equal major-mode 'gist-list-mode))
                          (error "Current buffer isn't a gist-list-mode buffer")
                        (buffer-name))
                    (format "*%s:%sgists*"
                            gh-profile-current-profile
                            (if (or (equal "" username)
                                    (eq 'current-user username))
                                ""
                              (format "%s's-" username)))))
         (api (gist-get-api nil))
         (username (or (and (null username) gist-list-buffer-user)
                       (and (not (or (null username)
                                     (equal "" username)
                                     (eq 'current-user username)))
                            username)
                       (gh-api-get-username api))))
    (when force-reload
      (pcache-clear (oref api :cache))
      (or background (message "Retrieving list of gists...")))
    (unless (and background (not (get-buffer bufname)))
      (let ((resp (gh-gist-list api username)))
        (gh-url-add-response-callback
         resp
         (lexical-let ((buffer bufname))
           (lambda (gists)
             (with-current-buffer (get-buffer-create buffer)
               (setq gist-list-buffer-user username)
               (gist-lists-retrieved-callback gists background)))))
        (gh-url-add-response-callback