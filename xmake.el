;;; xmake.el --- Interface for xmake                 -*- lexical-binding: t; -*-

;; Copyright (C) 2024  lizqwer scott

;; Author: lizqwer scott <lizqwerscott@gmail.com>
;; Keywords: lisp

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:


(provide 'xmake)
;;; xmake.el ends here


(defun xmake-installed-p ()
  "Check if xmake is installed."
  (eq (call-process-shell-command "xmake --version") 0))

(defun remove-ansi-color (str)
  "Remove ANSI color codes from STR."
  (replace-regexp-in-string "\x1b\\[[0-9;]*m" "" str))

(defun xmake-extract-target ()
  "Extract the target name from the xmake.lua file."
  (let ((xmake-lua-path (expand-file-name "xmake.lua" (file-name-directory (or (buffer-file-name) default-directory)))))
    (if (file-exists-p xmake-lua-path)
	    (with-temp-buffer
	      (insert-file-contents xmake-lua-path)
	      (goto-char (point-min))
	      (if (re-search-forward "target([\"']\\([^\"']+\\)[\"'])" nil t)
	          (match-string 1)
	        (message "No target found in xmake.lua")))
      (message "xmake.lua not found"))))

(defun xmake-command (command)
  "Run a xmake COMMAND asynchronously for 'xmake run' and synchronously for other commands, displaying the output in a buffer."
  (if (xmake-installed-p)
      (let ((buffer (get-buffer-create "*XMake Output*")))
	    (with-current-buffer buffer
	      (read-only-mode -1)
	      (erase-buffer)
	      (if (string-prefix-p "xmake run" command)
	          (start-process-shell-command "xmake-process" buffer command)
	        (progn
	          (call-process-shell-command command nil t)
	          (goto-char (point-min))
	          (setq output (remove-ansi-color (buffer-substring-no-properties (point-min) (point-max))))
	          (erase-buffer)
	          (insert output)
	          (display-buffer buffer))))
	    (message "Running '%s' %s..." command (if (string-prefix-p "xmake run" command) "asynchronously" "synchronously"))
	    t) ; Return true to indicate the command was executed
    nil)) ; Return nil to indicate the command was not executed due to xmake not being installed

;;;###autoload
(defun xmake-build ()
  "Run 'xmake' to build the project."
  (interactive)
  (xmake-command "xmake"))

;;;###autoload
(defun xmake-clean ()
  "Run 'xmake clean' to clean the project."
  (interactive)
  (xmake-command "xmake clean"))

(defvar xmake-process nil
  "Variable to store the process launched by 'xmake run'.")

;;;###autoload
(defun xmake-run ()
  "Run 'xmake run' with the target extracted from xmake.lua."
  (interactive)
  (let ((target (xmake-extract-target)))
    (if target
	    (progn
	      (setq xmake-process (start-process-shell-command "xmake-process" "*XMake Output*" (format "xmake run %s" target)))
	      (message "Running 'xmake run %s' asynchronously..." target)
	      (display-buffer "*XMake Output*"))
      (message "No target found to run."))))

;;;###autoload
(defun xmake-stop ()
  "Stop the process launched by 'xmake run'."
  (interactive)
  (if xmake-process
      (progn
	    (kill-process xmake-process)
	    (setq xmake-process nil)
	    (message "xmake run process stopped."))
    (message "No xmake run process running.")))

;;;###autoload
(defun xmake-compile-commands ()
  "Run 'xmake project -k compile_commands' to generate compile_commands.json."
  (interactive)
  (xmake-command "xmake project -k compile_commands"))

(provide 'xmake)
;;; xmake.el ends here
