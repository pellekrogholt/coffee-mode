;;
;; Major thanks to http://xahlee.org/emacs/elisp_syntax_coloring.html
;; the instructions.

;;
;; Commands
;;

(defvar coffee-command "coffee"
  "The CoffeeScript command used for evaluating code. Must be in your
path.")

(defvar coffee-js-mode 'js2-mode
  "The mode to use when viewing compiled JavaScript.")

(defvar coffee-compiled-buffer-name "*coffee-compiled*"
  "The name of the scratch buffer used when compiling CoffeeScript.")

(defun coffee-compile-buffer ()
  "Compiles the current buffer and displays the JS in the other buffer."
  (interactive)
  (save-excursion
    (coffee-compile-region (point-min) (point-max))))

(defun coffee-compile-region (start end)
  "Compiles a region and displays the JS in the other buffer."
  (interactive "r")

  (let ((buffer (get-buffer coffee-compiled-buffer-name)))
    (when buffer
      (kill-buffer buffer)))

  (call-process-region start end coffee-command nil
                       (get-buffer-create coffee-compiled-buffer-name)
                       nil
                       "-s" "-p" "--no-wrap")
  (switch-to-buffer-other-frame (get-buffer coffee-compiled-buffer-name))
  (funcall coffee-js-mode)
  (beginning-of-buffer))

;;
;; Define Language Syntax
;;

;; Assignment
(defvar coffee-type-regexp ".+?:")

;; Instance variables (implicit this)
(defvar coffee-constant-regexp "@\\w*\\|this")

;; Booleans
(defvar coffee-functions-regexp "\\b\\(true\\|false\\|yes\\|no\\|on\\|off\\)\\b")

;; Unused
(defvar coffee-event-regexp "")

;; JavaScript Keywords
(defvar coffee-js-keywords
      '("if" "else" "new" "return" "try" "catch"
        "finally" "throw" "break" "continue" "for" "in" "while"
        "delete" "instanceof" "typeof" "switch" "super" "extends"
        "class"))

;; Reserved keywords either by JS or CS.
(defvar coffee-js-reserved
      '("case" "default" "do" "function" "var" "void" "with"
        "const" "let" "debugger" "enum" "export" "import" "native"
        "__extends" "__hasProp"))

;; CoffeeScript keywords.
(defvar coffee-cs-keywords
      '("then" "unless" "and" "or" "is"
        "isnt" "not" "of" "by" "where" "when"))

;; Regular expression combining the above three lists.
(defvar coffee-keywords-regexp (regexp-opt
                                (append
                                 coffee-js-reserved
                                 coffee-js-keywords
                                 coffee-cs-keywords) 'words))


;; Create the list for font-lock.
;; Each class of keyword is given a particular face
(defvar coffee-font-lock-keywords
      `(
        (,coffee-type-regexp . font-lock-type-face)
        (,coffee-constant-regexp . font-lock-variable-name-face)
        (,coffee-event-regexp . font-lock-builtin-face)
        (,coffee-functions-regexp . font-lock-constant-face)
        (,coffee-keywords-regexp . font-lock-keyword-face)

        ;; note: order above matters. `coffee-keywords-regexp' goes last because
        ;; otherwise the keyword "state" in the function "state_entry"
        ;; would be highlighted.
        ))

;;
;; Helper Functions
;;

;; The command to comment/uncomment text
(defun coffee-comment-dwim (arg)
  "Comment or uncomment current line or region in a smart way.
For detail, see `comment-dwim'."
  (interactive "*P")
  (require 'newcomment)
  (let ((deactivate-mark nil) (comment-start "#") (comment-end ""))
    (comment-dwim arg)))

;;
;; Indentation
;;

;; The theory here is simple:
;; When you press TAB, indent the line unless doing so would make the
;; current line more than two indentation levels deepers than the
;; previous line. If that's the case, remove all indentation.
;;
;; Consider this code, with point at the position indicated by the
;; carot:
;;
;; line1()
;;   line2()
;;   line3()
;;      ^
;; Pressing TAB will produce the following code:
;;
;; line1()
;;   line2()
;;     line3()
;;        ^
;;
;; Pressing TAB again will produce this code:
;;
;; line1()
;;   line2()
;; line3()
;;    ^
;;
;; And so on.

(defun coffee-indent-line ()
  "Indent current line as CoffeeScript"
  (interactive)

  (save-excursion
    (let ((prev-indent 0) (cur-indent 0))
      ;; Figure out the indentation of the previous line
      (forward-line -1)
      (setq prev-indent (current-indentation))

      ;; Figure out the current line's indentation
      (forward-line 1)
      (setq cur-indent (current-indentation))

      ;; Shift one column to the left
      (backward-to-indentation 0)
      (insert-tab)

      ;; We're too far, remove all indentation.
      (when (> (- (current-indentation) prev-indent) tab-width)
        (backward-to-indentation 0)
        (delete-region (point-at-bol) (point))))))

;;
;; Define Major Mode
;;

(define-derived-mode coffee-mode fundamental-mode
  "coffee-mode"
  "Major mode for editing CoffeeScript..."

  (define-key coffee-mode-map (kbd "A-r") 'coffee-compile-buffer)
;;   (define-key coffee-mode-map (kbd "A-R") 'coffee-execute-line)
  (define-key coffee-mode-map [remap comment-dwim] 'coffee-comment-dwim)

  ;; code for syntax highlighting
  (setq font-lock-defaults '((coffee-font-lock-keywords)))

  ;; perl style comment: "# ..."
  (modify-syntax-entry ?# "< b" coffee-mode-syntax-table)
  (modify-syntax-entry ?\n "> b" coffee-mode-syntax-table)
  (setq comment-start "#")

  ;; single quote strings
  (modify-syntax-entry ?' "\"" coffee-mode-syntax-table)
  (modify-syntax-entry ?' "\"" coffee-mode-syntax-table)

  ;; regular expressions
  (modify-syntax-entry ?/ "\"" coffee-mode-syntax-table)
  (modify-syntax-entry ?/ "\"" coffee-mode-syntax-table)

  ;; indentation
  (make-local-variable 'indent-line-function)
  (setq indent-line-function 'coffee-indent-line)

  ;; no tabs
  (setq indent-tabs-mode nil)

  ;; clear memory
  (setq coffee-keywords-regexp nil)
  (setq coffee-types-regexp nil)
  (setq coffee-constants-regexp nil)
  (setq coffee-events-regexp nil)
  (setq coffee-functions-regexp nil))
