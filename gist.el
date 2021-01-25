
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