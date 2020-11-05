
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