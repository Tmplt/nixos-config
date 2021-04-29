(eval-when-compile
  (require 'package)
  (add-to-list 'package-archives
               '("melpa" . "https://melpa.org/packages/") t)
  (add-to-list
   'load-path "/etc/nix/pins/mu/share/emacs/site-lisp")
  (package-initialize)
  (setq use-package-always-ensure t))

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package)
  (require 'use-package-ensure))

;;;; Vanilla Emacs options

(server-start)

;; By default, use spaces for indentation
(setq-default indent-tabs-mode nil)

;; Ask y/n instead of yes/no
(fset 'yes-or-no-p 'y-or-n-p)

;; Confirm before closing emacs
(setq confirm-kill-emacs 'y-or-n-p)

;; Don't blink the cursor; I can see it perfectly
(blink-cursor-mode 0)

;; Don't assume that sentences should have two spaces after periods
(setq sentence-end-double-space nil)

;; Auto-revert buffer when file changes on disk
(global-auto-revert-mode t)

(setq view-read-only t)

;; Insert closing pair after point ant highlight matching pairs
(show-paren-mode t)
(setq electric-pair-pairs '(
                            (?\{ . ?\})
                            (?\( . ?\))
                            (?\[ . ?\])
                            (?\" . ?\")
                            ))
(electric-pair-mode t)

;; Disable some bindings
(global-unset-key (kbd "C-z"))          ; (suspend-frame)

;; Windows
(defun split-and-follow-horizontally ()
  (interactive)
  (split-window-below)
  (balance-windows)
  (other-window 1))
(global-set-key (kbd "C-x 2") 'split-and-follow-horizontally)

(defun split-and-follow-vertically ()
  (interactive)
  (split-window-right)
  (balance-windows)
  (other-window 1))
(global-set-key (kbd "C-x 3") 'split-and-follow-vertically)

(global-set-key (kbd "s-C-<left>") 'shrink-window-horizontally)
(global-set-key (kbd "s-C-<right>") 'enlarge-window-horizontally)
(global-set-key (kbd "s-C-<down>") 'shrink-window)
(global-set-key (kbd "s-C-<up>") 'enlarge-window)

(setq dired-listing-switches "-alsh --group-directories-first"
      dired-use-ls-dired t)

(setq mouse-autoselect-window t)

(defhydra hydra-zoom (global-map "<f2>")
  "zoom"
  ("g" text-scale-increase "in")
  ("l" text-scale-decrease "out"))

(use-package ace-window
  :bind
  ([remap other-window] . ace-window)
  ("M-o" . ace-window))

(use-package eldoc
  :diminish eldoc-mode)

;; eshell
(defalias 'edit 'find-file-other-window)
(defalias 'clean 'eshell/clear-scrollback)

(defun eshell-other-window ()
  "Create or visit an eshell buffer."
  (interactive)
  (if (not (get-buffer "*eshell*"))
      (progn
        (split-window-sensibly (selected-window))
        (other-window 1)
        (eshell))
    (switch-to-buffer-other-window "*eshell*")))

(global-set-key (kbd "<s-C-return>") 'eshell-other-window)

(setq gc-cons-threshold 20000000)       ; GC after 20M

;; Display line numbers
;; TODO: make this into a dolist
(when (version<= "26.0.50" emacs-version)
  ;; Line numbers
  (add-hook 'prog-mode-hook (lambda () (display-line-numbers-mode t)))
  (add-hook 'conf-mode-hook (lambda () (display-line-numbers-mode t)))
  (add-hook 'text-mode-hook (lambda () (display-line-numbers-mode t)))
  ;; Highlight current line
  (add-hook 'prog-mode-hook #'hl-line-mode)
  (add-hook 'conf-mode-hook #'hl-line-mode)
  (add-hook 'text-mode-hook #'hl-line-mode)
  ;; Auto-fill mode
  (add-hook 'text-mode-hook #'auto-fill-mode))

;; Disable unecessary GUI elements
(scroll-bar-mode -1)
(tool-bar-mode -1)
(menu-bar-mode -1)
(tooltip-mode -1)

(setq pdf-view-midnight-colors (cons "#ffffff" "#000000"))

(setq backward-delete-char-untabify-method 'nil)

;; store all backup and autosave files in the tmp dir
(setq backup-directory-alist
      `((".*" . ,temporary-file-directory)))
(setq auto-save-file-name-transforms
      `((".*" ,temporary-file-directory t)))

;; CC modes settings
(setq c-default-style "linux")

;; load a decent colour theme; press F12 to switch between light/dark
(unless (package-installed-p 'modus-vivendi-theme)
  (package-install 'modus-vivendi-theme))
(unless (package-installed-p 'modus-operandi-theme)
  (package-install 'modus-operandi-theme))
(load-theme 'modus-operandi t)
(defun themes-toggle ()
  (interactive)
  (if (eq (car custom-enabled-themes) 'modus-operandi)
      (progn
        (disable-theme 'modus-operandi)
        (load-theme 'modus-vivendi t))
    (disable-theme 'modus-vivendi)
    (load-theme 'modus-operandi t)))
(global-set-key [f12] 'themes-toggle)

;; Load a decent font
(add-to-list 'default-frame-alist '(font . "Go Mono"))

;; Delete any trailing whitespace on save
(add-hook 'before-save-hook 'delete-trailing-whitespace)

(defun toggle-editting-columns-balanced ()
  "Set both window margins so the edittable space is only 80 columns."
  (interactive)
  (let ((margins (window-margins)))
    (if (or (car margins) (cdr margins))
        (progn
          (set-face-background 'fringe nil)
          (set-window-margins nil 0 0))
      (let* ((change (max (- (window-width) 90) 0))
             (left (/ change 2))
             (right (- change left)))
        (set-face-background 'fringe "#ff6f6f") ; TODO: set accent colour from theme
        (set-window-margins nil left right)))))
(global-set-key [f9] 'toggle-editting-columns-balanced)

;; Remember the cursor position of files when reopening them
(setq save-place-file "~/.emacs.d/saveplace")
(if (version<= emacs-version "25.1")
    (progn
      (setq-default save-place t)
      (require 'saveplace))
  (save-place-mode 1))

(setq visible-bell t)

(if (version<= "27.1" emacs-version)
    (global-so-long-mode 1))

(defun kill-other-buffers ()
  "Kill all other buffers."
  (interactive)
  (mapc 'kill-buffer (delq (current-buffer) (buffer-list))))

;; Configure org-mode
(defun my/add-property-with-date-captured ()
  (interactive)
  (org-set-property "DATE_CAPTURED" (format-time-string "[%FT%T%z]")))

(use-package org
  :config
  (setq org-log-done t)
  (setq org-agenda-files (list "~/org/work.org"
                               "~/org/school.org"
                               "~/org/home.org"
                               "~/org/tasks.org"))
  (setq org-agenda-start-on-weekday 1)
  (setq org-list-allow-alphabetical t)
  (setq org-deadline-warning-days 5)
  (setq org-duration-format 'h:mm)
  (setq org-default-notes-file (concat org-directory "/notes.org")) ; used as a fallback for templates that do not specify file
  (setq org-src-fontify-natively t)
  ;; TODO use custom latex template/preamble ... for what? Thesis export?
  (setq org-capture-templates
        '(("t" "Task" entry (file+headline "~/org/tasks.org" "Tasks")
           "* TODO %?\n  %a")
          ("f" "Fleeting thought" item (file+headline "~/org/thoughts.org" "Thoughts")
           "- %? %U")
          ("d" "Dream" entry (file "~/org/dreams.org")
           "* %^{Summary}\n%?")
          ("j" "Journal entry" entry (file "~/org/journal.org")
           "* %^{Summary}\n%?")
          ("i" "Idea" entry (file+headline "~/org/ideas.org" "Ideas")
           "* %^{Summary}\n%?\n  %a")))
  (defface org-green
    '((t :foreground "green4"))
    "Face for green text in org mode")
  (defun my/org-mode-font-lock ()
    (font-lock-add-keywords
     nil
     '(("^\s*>\\(.*\\)" 0 'org-green t))))
  (setq org-format-latex-options (plist-put org-format-latex-options :scale 1.5))
  :hook
  (org-agenda-mode . hl-line-mode)
  (org-capture-before-finalize . my/add-property-with-date-captured)
  (org-mode . my/org-mode-font-lock)
  :bind
  ("C-c C-l" . 'org-store-link)
  ("C-c l" . 'org-insert-link)
  ("C-c a" . 'org-agenda)
  ("C-c c" . 'org-capture))    ; add a template for daily org-roam notes

(use-package org-agenda
  :ensure nil
  :hook
  (after-init . (lambda ()
                  (setq inhibit-splash-screen t)
                  (org-agenda-list)
                  (delete-other-windows)))
  :config
  (org-add-agenda-custom-command
   '("u" alltodo "Unscheduled"
     ((org-agenda-skip-function '(org-agenda-skip-entry-if 'scheduled 'deadline))
      (org-agenda-overriding-header "Unscheduled TODO entries: "))))
  :bind (:map org-agenda-mode-map
              ("x" . (lambda nil (interactive) (org-agenda-todo "CANCELLED")))))

(use-package org-crypt                  ; TODO set this up properly with a GPG key
  :ensure nil
  :config
  ;; (org-crypt-use-before-save-magic)
  (setq org-tags-exclude-from-inheritance '("crypt") ; TODO encrypt :secret: entries
        org-crypt-key nil))             ; use symmetric encryption

(use-package org-roam
  :diminish org-roam-mode
  :hook
  (after-init . org-roam-mode)
  :config
  (setq org-roam-directory "~/org/roam")
  :bind (("C-c n l" . org-roam)
         ("C-c n i" . org-roam-insert)
         ("C-c n f" . org-roam-find-file)
         ("C-c n j" . org-roam-jump-to-index)))

;; Disable latex-mode mathmode super- and sub-scripts
(setq tex-fontify-script nil)
(setq font-latex-fontify-script nil)

;;;; Package usage and configuration

;; configure emai
;; TODO send mail via postfix instead <http://pragmaticemacs.com/emacs/using-postfix-instead-of-smtpmail-to-send-email-in-mu4e/>
;; <https://etienne.depar.is/emacs.d/mu4e.html>
;; change From field on signature switch <https://github.com/djcb/mu/issues/776>
(use-package org-mu4e
  :ensure nil)
(use-package org-mime)
(use-package mu4e
  :ensure nil
  :config
  (setq send-mail-function 'smtpmail-send-it
        message-send-mail-function 'message-send-mail-with-sendmail
        sendmail-program "/run/current-system/sw/bin/msmtp"
        message-sendmail-extra-arguments '("--read-envelope-from"))
  ;; Required accoring to emacswiki when msmtp(1) is used
  (setq message-sendmail-f-is-evil 't)
  ;; Define accounts
  (setq mu4e-contexts
        `( ,(make-mu4e-context
             :name "uni"
             :enter-func (lambda () (mu4e-message "Entering uni context"))
             :leave-func (lambda () (mu4e-message "Leaving uni context"))
             ;; Match based on the message's contact field
             :match-func (lambda (msg)
                           (when msg
                             (mu4e-message-contact-field-matches msg :to "vikson-6@student.ltu.se")))
             :vars `( (user-mail-address  . "vikson-6@student.ltu.se")
                      (user-full-name     . "Viktor Sonesten")
                      (mu4e-sent-folder   . "/uni/[Gmail].Sent Mail")
                      (mu4e-drafts-folder . "/uni/[Gmail].Drafts")
                      (mu4e-trash-folder  . "/uni/[Gmail].Trash")
                      (mu4e-refile-folder . "/uni/archive")))
           ,(make-mu4e-context
             :name "tmplt"
             :enter-func (lambda () (mu4e-message "Entering tmplt context"))
             :leave-func (lambda () (mu4e-message "Leaving tmplt context"))
             ;; Match based on the message's contact field
             :match-func (lambda (msg)
                           (when msg
                             (mu4e-message-contact-field-matches msg :to "v@tmplt.dev")))
             :vars `( (user-mail-address  . "v@tmplt.dev")
                      (user-full-name     . "Viktor Sonesten")
                      (mu4e-sent-folder   . "/tmplt/Sent")
                      (mu4e-drafts-folder . "/tmplt/Drafts")
                      (mu4e-trash-folder  . "/tmplt/Trash")
                      (mu4e-refile-folder . "/tmplt/archive")))
           ,(make-mu4e-context
             :name "personal"
             :enter-func (lambda () (mu4e-message "Entering personal context"))
             :leave-func (lambda () (mu4e-message "Leaving personal context"))
             ;; Match based on the message's contact field
             :match-func (lambda (msg)
                           (when msg
                             (mu4e-message-contact-field-matches msg :to "viktor.sonesten@mailbox.org")))
             :vars `( (user-mail-address  . "viktor.sonesten@mailbox.org")
                      (user-full-name     . "Viktor Sonesten")
                      (mu4e-sent-folder   . "/personal/Sent")
                      (mu4e-drafts-folder . "/personal/Drafts")
                      (mu4e-trash-folder  . "/personal/Junk")
                      (mu4e-refile-folder . "/personal/archive")))
           ,(make-mu4e-context
             :name "ludd"
             :enter-func (lambda () (mu4e-message "Entering ludd context"))
             :leave-func (lambda () (mu4e-message "Leaving ludd context"))
             ;; Match based on the message's contact field
             :match-func (lambda (msg)
                           (when msg
                             (mu4e-message-contact-field-matches msg :to "tmplt@ludd.ltu.se")))
             :vars `( (user-mail-address  . "tmplt@ludd.ltu.se")
                      (user-full-name     . "tmplt")
                      (mu4e-sent-folder   . "/ludd/Sent")
                      (mu4e-drafts-folder . "/ludd/Drafts")
                      (mu4e-trash-folder  . "/ludd/Trash")
                      (mu4e-refile-folder . "/ludd/archive")))))
  ;; Choose default context
  (setq mu4e-context-policy 'pick-first)
  ;; Show full addresses in the view message (instead of just names)
  (setq mu4e-view-show-addresses t)
  ;; Don't keep message buffers around
  (setq message-kill-buffer-on-exit t)
  ;; Use as emacs-global MUA; compose-mail thus uses mu4e
  (setq mail-user-agent 'mu4e-user-agent)
  ;; Don't ask to quit
  (setq mu4e-confirm-quit nil)
  ;; View mail in browser
  (defun ed/mu4e-msgv-action-view-in-browser (msg)
    "View the body of the message in a web browser."
    (interactive)
    (let ((html (mu4e-msg-field (mu4e-message-at-point t) :body-html))
          (tmpfile (format "%s/%d.html" temporary-file-directory (random))))
      (unless html (error "No html part for this message"))
      (with-temp-file tmpfile
        (insert
         "<html>"
         "<head><meta http-equiv=\"content-type\""
         "content=\"text/html;charset=UTF-8\">"
         html))
      (browse-url (concat "file://" tmpfile))))
  (add-to-list 'mu4e-view-actions
               '("View in browser" . ed/mu4e-msgv-action-view-in-browser) t)
  ;; Configure date formats
  (setq mu4e-date-format-long "%F"
        mu4e-headers-time-format "%R"
        mu4e-headers-date-format "%d/%m/%+4Y"
        mu4e-view-date-format "%a %d %b %Y %R %Z"
        message-citation-line-format "%f writes:" ; TODO: this depends on language
        message-citation-line-function 'message-insert-formatted-citation-line)
  ;; Apply recommendations as per useplaintext.email
  (setq-default fill-column 72)
  (setq mu4e-compose-format-flowed t
        fill-flowed-encode-column fill-column
        message-cite-reply-position 'below)
  ;; Warn if expected attachments are missing
  (defun mbork/message-attachment-present-p ()
    "Return t if an attachment is found in the current message."
    (save-excursion
      (save-restriction
        (widen)
        (goto-char (point-min))
        (when (search-forward "<#part" nil t) t))))
  (defcustom tmplt/message-attachment-intent-re
    (regexp-opt '("attach"
                  "attached"
                  "attachment"
                  "bifogar"
                  "bifogad"))
    "A regex which - if found in the message, and if there is no
attachment - should launch the no-attachment warning.")
  (defcustom mbork/message-attachment-reminder
    "Are you sure you want to send this message without any attachment? "
    "The default question asked when trying to send a message
containing `mbork/message-attachment-intent-re' without an
actual attachment.")
  (defun mbork/message-warn-if-no-attachments ()
    "Ask the user if s?he wants to send the message even though
there are no attachments."
    (when (and (save-excursion
	         (save-restriction
		   (widen)
		   (goto-char (point-min))
		   (re-search-forward tmplt/message-attachment-intent-re nil t)))
	       (not (mbork/message-attachment-present-p)))
      (unless (y-or-n-p mbork/message-attachment-reminder)
        (keyboard-quit))))
  :hook
  (message-send . (lambda nil (mbork/message-warn-if-no-attachments)))
  :bind
  ("C-x m" . (lambda ()
               (interactive)
               (mu4e-headers-search-bookmark "flag:unread AND NOT flag:trashed")))
  ;; TODO quit mu4e when done?
  ;; NOTE context query is overridden by mu update status
  ("C-x C-m" . 'compose-mail))

(use-package elfeed
  :config
  (add-hook 'elfeed-new-entry-hook
            (elfeed-make-tagger :feed-url "youtube\\.com"
                                :add '(video youtube)))
  (defun youtube-xml (cid) (format "https://www.youtube.com/feeds/videos.xml?channel_id=%s" cid))
  (setq elfeed-feeds
        `(("https://planet.emacslife.com/atom.xml" emacs)
          ;; TODO paid LWN articles (contains "[$]") become free after a few weeks. Delay their display until they are free.
          ;;      In case delay isn't static (or if it is subject to change) we can grep for the date by curling the link.
          ("https://lwn.net/headlines/rss" linux)
          ("https://interrupt.memfault.com/blog/feed.xml" embedded)
          ("https://embeddedartistry.com/feed/" embedded)
          ("https://drewdevault.com/blog/index.xml" blog)))
  :bind (("C-x w" . 'elfeed)
         :map elfeed-search-mode-map
         ;; TODO understand this lambda
         ("C-c o" . (lambda (&optional use-generic-p) ; open in mpv
                      (interactive "P")
                      (let ((entries (elfeed-search-selected)))
                        (cl-loop for entry in entries
                                 do (elfeed-untag entry 'unread)
                                 when (elfeed-entry-link entry)
                                 do (async-shell-command (format "mpv '%s'" it))) ; TODO kill buffer afterwards
                        (mapc #'elfeed-search-update-entry entries)
                        (unless (use-region-p) (forward-line)))))))

(use-package rust-mode
  :bind
  ("C-c C-c" . (lambda ()
                 (interactive)
                 (save-buffer)
                 (rust-compile)))
  ("C-c C-r" . (lambda ()
                 (interactive)
                 (save-buffer)
                 (rust-run))))
(use-package nix-mode)
(use-package haskell-mode)
(use-package yaml-mode)
(use-package cmake-mode)
(use-package diff-hl
  :config
  (global-diff-hl-mode)
  (add-hook 'magit-pre-refresh-hook 'diff-hl-magit-pre-refresh)
  (add-hook 'magit-post-refresh-hook 'diff-hl-magit-post-refresh))

(use-package magit
  :bind
  ("C-x g" . 'magit-status)
  ("C-c g" . 'magit-file-dispatch))

;; highlight the following strings
;;;; TODO: add the following keywords for Org mode:
;; TODO: something that needs doing
;; DONE: something that's already done
;; INPROGRESS: something I'm currently doing
;; WAITING: waiting for someone else before doing anything
;; NEEDSREVIEW: there is a PR for this; it needs someone to look at it
;; HOLD: this is in permament hold until further notice
;; CANCELLED: I don't need to do this any more
;; SOMEDAY: I'd like to do this someday in the waaaay off future
(use-package hl-todo
  :hook
  (prog-mode . hl-todo-mode)
  (text-mode . hl-todo-mode)
  :config
  (setq hl-todo-keyword-faces
        '(("TODO"   . warning)          ; default face is red
          ("FIXME"  . error)
          ("NOTE"   . success)
          ("XXX"    . error))))


(use-package mpdel
  :bind (("C-x u" . 'mpdel-core-map)    ; TODO replace this with some 'mpdel-status that behaves like 'magit-status
         :map mpdel-core-map
         ("Q" . (lambda ()              ; Mpdel Stacks buffers when changing views/modes; quit them recursively
                  (interactive)
                  (while (string-match-p "mpdel-.*-mode" (symbol-name major-mode))
                    (quit-window))))
         ;; TODO get rid of the "Ready!" message
         ("z" . (lambda ()              ; Toggle random
                  (interactive)
                  (if libmpdel--random
                      (libmpdel-playback-unset-random)
                    (libmpdel-playback-set-random))
                  (message "mpd: random: %s" (if (not libmpdel--random) ; I have no idea why I must negate here. Behaves as expected in 'eval-expression
                                                 "on" "off"))))))

(use-package ivy
  :init
  (ivy-mode 1))
(use-package counsel
  :init
  (counsel-mode 1))
(use-package swiper
  :bind ("C-s" . 'swiper))

(use-package diminish
  :init
  (diminish 'auto-fill-function))       ; auto-fill-mode

(use-package which-key
  :diminish which-key-mode
  :init
  (which-key-mode))

(use-package avy
  :bind
  ("C-;" . 'avy-goto-char-timer)
  ("C-'" . 'avy-goto-line))

(use-package pdf-tools
  :config
  (setq-default pdf-view-display-size 'fit-width)
  (define-key pdf-view-mode-map (kbd "C-s") 'isearch-forward)
  :init
  (pdf-tools-install))

(use-package org-pdftools
  :hook (org-mode . org-pdftools-setup-link))

(use-package projectile
  :config
  (setq projectile-enable-caching t)
  :init
  (projectile-mode +1)
  :bind (:map projectile-mode-map
              ("C-c p" . projectile-command-map)))

(use-package openwith
  :custom
  (openwith-associations ((lambda (asocs)
                            (cl-loop for (prog . exts) in asocs
                                     collect (list (concat "\\." (regexp-opt exts) "\\'") prog '(file))))
                          '(("mpv" . ("mkv" "mp4" "webm")))))
  :config
  (openwith-mode t))

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("96c56bd2aab87fd92f2795df76c3582d762a88da5c0e54d30c71562b7bf9c605" default))
 '(package-selected-packages
   '(mpdel elfeed diff-hl json-mode org-mime doom-themes slime use-package dashboard modus-vivendi-theme yaml-mode rust-mode nix-mode modus-operandi-theme magit latex-preview-pane hl-todo haskell-mode cmake-mode auctex)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
