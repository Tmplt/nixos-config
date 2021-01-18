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
(define-key *root-map* (kbd "t") "exec telegram-desktop")
(define-key *root-map* (kbd "q") "exec qutebrowser") ; TODO focus if it exists, see emacs cmd impl.
(define-key *root-map* (kbd "C-w") "windowlist")
(define-key *root-map* (kbd "m") "mode-line")
(define-key *root-map* (kbd "c") "exec st")
(define-key *root-map* (kbd "C-c") "exec st")

;; Bind XF86 keys
(define-key stumpwm:*top-map*
  (stumpwm:kbd "XF86AudioMute")
  "exec pactl set-sink-mute @DEFAULT_SINK@ toggle")
(define-key stumpwm:*top-map*
  (stumpwm:kbd "XF86AudioMicMute")
  "exec pactl set-source-mute @DEFAULT_SOURCE@ toggle")
(define-key stumpwm:*top-map*
  (stumpwm:kbd "XF86AudioRaiseVolume")
  "exec pactl set-sink-mute @DEFAULT_SINK@ false && pactl
set-sink-volume @DEFAULT_SINK@ +2%")
(define-key stumpwm:*top-map*
  (stumpwm:kbd "XF86AudioLowerVolume")
  "exec pactl set-sink-mute @DEFAULT_SINK@ false && pactl
set-sink-volume @DEFAULT_SINK@ -2%")
(define-key stumpwm:*top-map*
  (stumpwm:kbd "XF86MonBrightnessUp")
  "exec light -A 5")
(define-key stumpwm:*top-map*
  (stumpwm:kbd "XF86MonBrightnessDown")
  "exec light -U 5")
(define-key stumpwm:*top-map*
  (stumpwm:kbd "XF86ScreenSaver")
  "exec loginctl lock-session")

;; Configure mode-line
(setf *mode-line-screen-position* :top
      *mode-line-frame-position* :top
      *mode-line-timeout* 2)           ; update at least every 2 seconds

(defun show-battery-charge ()
  (let ((raw-battery (run-shell-command "acpi | cut -d, -f2" t)))
    (substitute #\Space #\Newline raw-battery)))

(defun show-battery-state ()
  (let ((raw-battery (run-shell-command "acpi | cut -d: -f2 | cut -d, -f1" t)))
    (substitute #\Space #\Newline raw-battery)))

(defun show-hostname ()
  (let ((host-name (run-shell-command "hostname" t)))
    (substitute #\Space #\Newline host-name)))

(defun show-unread-emails ()
  (let ((unread-mail (run-shell-command "mu find flag:unread | wc -l" t)))
    (substitute #\Space #\Newline unread-mail)))

(defun show-date ()
  (let ((raw-date (run-shell-command "date '+%a %d %b %R'" t)))
    (substitute #\Space #\Newline raw-date)))


(setf *screen-mode-line-format*
      (list
       '(:eval (show-hostname))
       "| Battery:"
       '(:eval (show-battery-charge))
       '(:eval (show-battery-state))
       "| "  '(:eval (show-date))
       "| Mails: " '(:eval (show-unread-emails))
       "| %g"))
(toggle-mode-line (current-screen) (current-head))
