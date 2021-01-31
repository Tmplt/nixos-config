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

;; windows
(setf *window-border-style* :thin
      *ignore-wm-inc-hints* nil)
(set-win-bg-color "black")
(set-unfocus-color "black")
(set-focus-color "white")

;; groups
(grename "I")
(gnewbg "II")
(gnewbg "III")

;; Configure mode-line
(setf *mode-line-position* :bottom
      *mode-line-timeout* 2           ; update at least every 2 seconds
      *window-format* "%m%n%s%c"
      *time-modeline-string* "%a %d %b %R"
      *mode-line-foreground-color* "white"
      *mode-line-background-color* "black"
      *modle-line-border-color* "white"
      *mode-line-pad-x* 5
      *mode-line-pad-l* 0
      *mode-line-border-width* 0)
(define-key *root-map* (kbd "m") "mode-line")

(defun tmplt/eval-shell (cmd)
  (let ((retstr (run-shell-command cmd t)))
    (substitute #\Space #\Newline retstr)))

;; TODO center (show-date)
(setf *screen-mode-line-format*
      (list
       "[%d] [^B%n^b]%W^>"
       "[ "
       "BAT "
       '(:eval (tmplt/eval-shell "acpi | awk '{print $4}'")) ; BAT percentage
       '(:eval (tmplt/eval-shell "acpi | awk '{print $3}' | cut -c1")) ; BAT state
       "| MAIL: "
       '(:eval (tmplt/eval-shell "mu find flag:unread AND NOT flag:trashed | wc -l"))
       "]"))
(toggle-mode-line (current-screen) (current-head))
