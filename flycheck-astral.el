;;; flycheck-astral.el --- Support ruff and ty in flycheck

;; Copyright (C) 2025 Jacob Wilkins <jacob.wilkins@stfc.ac.uk>
;;
;; Author: Jacob Wilkins <jacob.wilkins@stfc.ac.uk>
;; Created: 17 May 2025
;; Version: 1.0
;; Package-Requires: ((flycheck "0.18"))
;; Modified from https://github.com/flycheck/flycheck/issues/1974#issuecomment-1343495202

;;; Commentary:

;; This package adds support for ruff and ty to flycheck.  To use it, add
;; to your init.el:

;; (require 'flycheck-astral)
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

(defcustom ty-custom-python ""
  "Location of custom Python for e.g. pyenv."
  :type 'string
  :get (lambda (symb) (if (not (string-empty-p symb)) (expand-file-name symb)))
  )

(flycheck-define-checker python-ty
  "A Python syntax and style checker using the ty utility.
To override the path to the ty executable, set
`flycheck-python-ty-executable'.
See URL `http://pypi.python.org/pypi/ty'."
  :command ("ty"
            "check"
            "--output-format" "concise"
            (option "--python" ty-custom-python)
            source)
  :error-filter (lambda (errors)
                  (let ((errors (flycheck-sanitize-errors errors)))
                    (seq-map #'flycheck-flake8-fix-error-level errors)))
  :error-patterns
  (
   (error line-start
          "error[" (id (one-or-more (any alpha "-"))) "] "
          (file-name) ":" line ":" (optional column ":") " "
          (message (one-or-more not-newline))
          line-end)
   (warning line-start
          "warning[" (id (one-or-more (any alpha "-"))) "] "
          (file-name) ":" line ":" (optional column ":") " "
          (message (one-or-more not-newline))
          line-end)
   (info line-start
          "info[" (id (one-or-more (any alpha "-"))) "] "
          (file-name) ":" line ":" (optional column ":") " "
          (message (one-or-more not-newline))
          line-end)
   )
  :predicate (lambda () (buffer-file-name))

  :modes (python-mode python-ts-mode)

  :error-explainer
  (lambda (err)
    (let ((error-code (flycheck-error-id err))
          (url "https://github.com/astral-sh/ty/blob/main/docs/reference/rules.md#"))
      (and error-code `(url . ,(concat url error-code)))))

  )


(flycheck-define-checker python-ruff-cust
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
  :next-checkers ((t . python-ty))
  :modes (python-mode python-ts-mode)

  :error-explainer
  (lambda (err)
    (let ((error-code (flycheck-error-id err))
          (url "https://docs.astral.sh/ruff/rules/"))
      (and error-code `(url . ,(concat url error-code)))))
  )


(add-to-list 'flycheck-checkers 'python-ty)
(add-to-list 'flycheck-checkers 'python-ruff-cust)

(provide 'flycheck-astral)
;;; flycheck-astral.el ends here
