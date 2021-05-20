(defvar *my-keymap* (make-keymap "my-map"))
(define-key *my-keymap*
  "C-a" 'nyxt/web-mode:scroll-to-top
  "C-e" 'nyxt/web-mode:scroll-to-bottom)
(define-mode my-mode ()
  ((keymap-scheme (keymap:make-scheme
                   scheme:cua *my-keymap*
                   scheme:emacs *my-keymap*
                   scheme:vi-normal *my-keymap*))))
(define-configuration (buffer web-buffer)
  ((default-modes (append '(my-mode) %slot-default%))))

(define-configuration (buffer web-buffer)
  ((default-modes (append '(emacs-mode) %slot-default%))))

(define-configuration prompt-buffer
    ((default-modes (append '(emacs-mode) %slot-default%))))
