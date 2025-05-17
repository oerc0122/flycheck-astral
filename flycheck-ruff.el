;;; flycheck-ruff.el --- Support ruff in flycheck

;; Copyright (C) 2025 Jacob Wilkins <jacob.wilkins@stfc.ac.uk>
;;
;; Author: Jacob Wilkins <jacob.wilkins@stfc.ac.uk>
;; Created: 20 January 2025
;; Version: 1.0
;; Package-Requires: ((flycheck "0.18"))
;; Modified from https://github.com/flycheck/flycheck/issues/1974#issuecomment-1343495202

;;; Commentary:

;; This package adds support for castep-linter to flycheck.  To use it, add
;; to your init.el:

;; (require 'flycheck-ruff)
;; (add-hook 'python-mode-hook 'flycheck-mode)

;;; License:

;; This file is not part of GNU Emacs.
;; However, it is distributed under the same license.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:
(require 'flycheck)

(flycheck-define-checker python-ruff
  "A Python syntax and style checker using the ruff utility.
To override the path to the ruff executable, set
`flycheck-python-ruff-executable'.
See URL `http://pypi.python.org/pypi/ruff'."
  :command ("ruff" "check"
            "--output-format=concise"
            (eval (when buffer-file-name
                    (concat "--stdin-filename=" buffer-file-name)))
            "-")
  :standard-input t
  :error-filter (lambda (errors)
                  (let ((errors (flycheck-sanitize-errors errors)))
                    (seq-map #'flycheck-flake8-fix-error-level errors)))
  :error-patterns
  (
   (error line-start
          (file-name) ":" line ":" (optional column ":") " "
          (id (one-or-more (any alpha))) ": "
          (message (one-or-more not-newline))
          line-end)
   (warning line-start
            (file-name) ":" line ":" (optional column ":") " "
            (id (one-or-more (any alpha)) (one-or-more digit)) " "
            (message (one-or-more not-newline))
            line-end)
   )
  :modes (python-mode python-ts-mode))

(add-to-list 'flycheck-checkers 'python-ruff)
(flycheck-add-next-checker 'python-ruff 'python-ty)

(provide 'flycheck-ruff)
;;; flycheck-ruff.el ends here
