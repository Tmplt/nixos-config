;; X11 is started via a system-wide service, but the below services are
;; only available as user services, so they cannot be automatically
;; started. We instead start them here "manually".
(run-shell-command "systemctl --user start picom")

;; Configure a preferable mouse pointer
(run-shell-command "xsetroot -cursor_name left_ptr")

;; Give us a nice wallpaper
;; TODO randomize this on every start
(run-shell-command "feh --bg-fill ~/wallpapers/shoebill.jpg")

;; Change window focus on mouse click
(setf *mouse-focus-policy* :click)

;; Fix mousewheel in some programs (nyxt, for example)
(setf (getenv "GDK_CORE_DEVICE_EVENTS") "1")

(define-key *root-map* (kbd "e") "exec emacsclient -c -a emacs")
(define-key *root-map* (kbd "C-e") "emacs")
