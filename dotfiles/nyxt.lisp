(defvar *my-keymap* (make-keymap "my-map"))
;; TODO copy prompt-buffer binds from sheme:cu (alt-f, alt-backspace, etc.)
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

;; TODO add command to open hint with mpv
;; (define-command play-video-in-hint (&optional (buffer (current-buffer)))
;;   "Play video from a hint with mpv."
;;   (uiop:run-program (list "mpv" (object-string (url buffer)))))

;; (define-command play-video-in-current-page (&optional (buffer (current-buffer)))
;;   "Play video in the currently open buffer."
;;   (uiop:run-program (list "mpv" (nyxt:object-string (url buffer)))))
