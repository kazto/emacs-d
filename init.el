;; init.el --- My init.el -*- lexical-binding: t -*-
;; Configurations for Emacs
;; kazto <kazto@kazto.dev>

(setq user-full-name "kazto")
(setq user-mail-address "kazto@kazto.dev")

;;
(defconst my/before-load-init-time (current-time))

;;;###autoload
(defun my/load-init-time ()
  "Loading time of user init files including time for `after-init-hook'."
  (let ((time1 (float-time
                (time-subtract after-init-time my/before-load-init-time)))
        (time2 (float-time
                (time-subtract (current-time) my/before-load-init-time))))
    (message (concat "Loading init files: %.0f [msec], "
                     "of which %.f [msec] for `after-init-hook'.")
             (* 1000 time1) (* 1000 (- time2 time1)))))
(add-hook 'after-init-hook #'my/load-init-time t)

(defvar my/tick-previous-time my/before-load-init-time)

;;;###autoload
(defun my/tick-init-time (msg)
  "Tick boot sequence at loading MSG."
  (when my/loading-profile-p
    (let ((ctime (current-time)))
      (message "---- %5.2f[ms] %s"
               (* 1000 (float-time
                        (time-subtract ctime my/tick-previous-time)))
               msg)
      (setq my/tick-previous-time ctime))))

(defun my/emacs-init-time ()
  "Emacs booting time in msec."
  (interactive)
  (message "Emacs booting time: %.0f [msec] = `emacs-init-time'."
           (* 1000
              (float-time (time-subtract
                           after-init-time
                           before-init-time)))))

(add-hook 'after-init-hook #'my/emacs-init-time)

;; -- autoload if found -------------------------------------------------------------
(defun autoload-if-found (functions file &optional docstring interactive type)
  "Set autoload if FILE has found."
  (when (locate-library file)
    (dolist (f functions)
      (autoload f file docstring interactive type))))

;; -- show trailing whitespace ------------------------------------------------------
(defun my/disable-show-trailing-whitespace ()
  (setq show-trailing-whitespace nil))

(with-eval-after-load 'comint
  (add-hook 'comint-mode-hook #'my/disable-show-trailing-whitespace))

(with-eval-after-load 'esh-mode
  (add-hook 'eshell-mode-hook #'my/disable-show-trailing-whitespace))

(with-eval-after-load 'minibuffer
  (add-hook 'minibuffer-inactive-mode-hook #'my/disable-show-trailing-whitespace))

(with-eval-after-load 'text-mode
  (add-hook 'text-mode-hook #'my/disable-show-trailing-whitespace))

;; -- display line number
(autoload-if-found '(global-display-line-numbers-mode) "display-line-numbers" nil t)

(with-eval-after-load 'display-line-numbers
  (setopt display-line-numbers-grow-only t))

;; -- electric pair
(add-hook 'emacs-startup-hook #'electric-pair-mode)

;; -- minibuffer
(with-eval-after-load 'minibuffer
  (define-key minibuffer-mode-map (kbd "C-j") #'exit-minibuffer)
  (define-key minibuffer-mode-map (kbd "M-RET") #'exit-minibuffer))

(setq enable-recursive-minibuffers t)

;; -- uniqify
(with-eval-after-load 'uniquify
  (setopt uniquify-buffer-name-style 'post-forward-angle-brackets))

;; -- prohibit kill buffer
(add-hook 'emacs-startup-hook
          #'(lambda ()
              (with-current-buffer "*scratch*"
                (emacs-lock-mode 'kill))
              (with-current-buffer "*Messages*"
                (emacs-lock-mode 'kill))))

;; -- kill ring
(setopt kill-ring-max 100000)

;; -- truncate lines
(setq truncate-lines t)
(setq truncate-partial-width-windows t)

;; -- recentf
(autoload-if-found '(recentf-mode) "recentf" nil t)

(add-hook 'emacs-startup-hook #'recentf-mode)

(with-eval-after-load 'recentf
  ;; config
  (setopt recentf-auto-cleanup 'never)
  (setopt recentf-max-menu-items 10000)
  (setopt recentf-max-saved-items 10000)
  (setopt recentf-save-file  (expand-file-name "~/.emacs.d/.recentf"))
  )

;; -- elpaca init -------------------------------------------------------------------
(defvar elpaca-installer-version 0.11)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1 :inherit ignore
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (<= emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                  ,@(when-let* ((depth (plist-get order :depth)))
                                                      (list (format "--depth=%d" depth) "--no-single-branch"))
                                                  ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (let ((load-source-file-function nil)) (load "./elpaca-autoloads"))))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

;; -----------------------------------------------------------------------------------------

(elpaca markdown-mode)
(elpaca affe)
(elpaca swiper)
(elpaca counsel)
(elpaca prescient)
(elpaca corfu)
(elpaca corfu-prescient)
(elpaca consult)
(elpaca vertico)
(elpaca marginalia)
(elpaca orderless)
(elpaca cape)
(elpaca puni)
(elpaca biomejs-format)
(elpaca flymake)
(elpaca flymake-biome)
(elpaca which-key)
(elpaca eglot)
(elpaca vterm)
; (elpaca treesit)
(elpaca tree-sitter)
(elpaca tree-sitter-langs)
(elpaca tide)
; (elpaca files)

(elpaca-wait)

(use-package corfu
  :init
  (global-corfu-mode)
  :custom
  (corfu-cycle t)
  (corfu-auto t)
  (corfu-auto-delay 0)
  (corfu-auto-prefix 1)
  (corfu-separator ?\s)
  (corfu-quit-at-boundary 'never)
  :bind
  (:map corfu-map
	("TAB" . corfu-complete)
	("RET" . nil))
  )

(use-package vertico
  :init
  (vertico-mode)
  :config
  (setq vertico-count 20)
  )

(use-package marginalia
  :after vertico
  :init
  (marginalia-mode))

(use-package consult
  :bind
  (
   ("C-c C-x" . consult-mode-command)
   ("C-x b" . consult-buffer) 
   :map isearch-mode-map
   ("M-e" . consult-isearch-history)
   ("M-s e" . consult-isearch-history)
   ("M-s l" . consult-line)           
   ("M-s L" . consult-line-multi)     
   :map minibuffer-local-map
   ("M-s" . consult-history)          
   ("M-r" . consult-history)
   )
  :init
  (advice-add #'register-preview :override #'consult-register-window)
  (setq register-preview-delay 0.5)
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)
  :config
  (consult-customize
   consult-theme :preview-key '(:debounce 0.2 any)
   consult-ripgrep consult-git-grep consult-grep consult-man
   consult-bookmark consult-recent-file consult-xref
   consult--source-bookmark consult--source-file-register
   consult--source-recent-file consult--source-project-recent-file

   :preview-key '(:debounce 0.4 any))
  (setq consult-narrow-key "<")
  )

(use-package affe
  :after orderless
  :config
  (consult-customize affe-grep :preview-key "M-.")
  (when (executable-find "rg")
    (setq affe-grep-command "rg --null --line-buffered --color=never --max-columns=1000 --no-heading --line-number -v ^$ ."))
  :bind
  (("C-c s f" . affe-find)
   ("C-c s g" . affe-grep))
  )

(use-package cape
  :bind
  ("C-c p" . cape-prefix-map)
  :init
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-keyword)
  (add-to-list 'completion-at-point-functions #'cape-abbrev)
  (add-to-list 'completion-at-point-functions #'cape-ispell)
  (add-to-list 'completion-at-point-functions #'cape-symbol)
  )

(use-package orderless
  :custom
  (completion-styles '(orderless)))

(use-package paren
  :init
  (show-paren-mode))

(use-package puni
  :init
  (puni-global-mode)
  :config
  (add-hook 'term-mode-hook #'puni-disable-puni-mode)
  (add-hook 'vterm-mode-hook #'puni-disable-puni-mode))

(use-package which-key
  :config
  (which-key-mode)
  (which-key-setup-side-window-right)
  )

(use-package eglot
  ;; :hook
  ;; (prog-mode . eglot-ensure)
  ;; :config
  ;; (add-to-list 'eglot-server-programs ')
  :bind (("M-t" . xref-find-definitions)
	 ("M-r" . xref-find-references)
	 ("C-t" . xref-go-back)))

;; (use-package files
;;   :init
;;   (auto-save-visited-mode)
;;   :config
  
;;   )

(use-package treesit
  :ensure nil
  :when (treesit-available-p)
  :config  
  (setq treesit-language-source-alist
        '((typescript . ("https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src"))
          (tsx . ("https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src"))
          (javascript . ("https://github.com/tree-sitter/tree-sitter-javascript" "master" "src"))))
  (setq major-mode-remap-alist
        '((typescript-mode . typescript-ts-mode)
          (js-mode . js-ts-mode)
          (css-mode . css-ts-mode)
          (json-mode . json-ts-mode)))
  (setq treesit-font-lock-level 4)
  )

(use-package tree-sitter
  :hook
  ((typescript-ts-mode . tree-sitter-hl-mode)
   (tsx-ts-mode . tree-sitter-hl-mode))
  :config
  (global-tree-sitter-mode)
  )

(use-package typescript-ts-mode
  :mode (("\\\\.tsx\\\\'" . tsx-ts-mode)
	 ("\\\\.tsx\\\\'" . tsx-ts-mode))
  :config
  (setq typescript-ts-mode-indent-offset 2)
  )

(use-package tree-sitter-langs
  :after tree-sitter
  :config
  (tree-sitter-require 'tsx)
  (add-to-list 'tree-sitter-major-mode-language-alist '(tsx-ts-mode . tsx))
  )

(use-package tide
  :hook (tsx-ts-mode . setup-tide-mode)
  :config
  (defun setup-tide-mode ()
    (interactive)
    (tide-setup)
    (flycheck-mode +1)
    (setq flycheck-check-syntax-automatically '(save mode-enabled))
    (eldoc-mode +1)
    (tide-hl-identifier-mode +1)
    )
  )

(elpaca-process-queues)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages nil)
 '(savehist-additional-variables '(kill-ring)))

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(ansi-color-blue ((t (:background "dodgerblue" :foreground "dodgerblue"))))
 '(ansi-color-bright-black ((t (:background "snow4" :foreground "snow4"))))
 '(ansi-color-green ((t (:background "greenyellow" :foreground "greenyellow"))))
 '(font-lock-builtin-face ((t (:foreground "cyan"))))
 '(font-lock-comment-face ((t (:foreground "green"))))
 '(font-lock-constant-face ((t (:foreground "cyan1"))))
 '(font-lock-function-name-face ((t (:foreground "salmon"))))
 '(font-lock-keyword-face ((t (:foreground "aquamarine"))))
 '(font-lock-string-face ((t (:foreground "gold"))))
 '(font-lock-type-face ((t (:foreground "lawngreen"))))
 '(font-lock-variable-name-face ((t (:foreground "salmon"))))
 '(highlight ((t (:background "darkseagreen4"))))
 '(link ((t (:foreground "mediumorchid" :underline t))))
 '(tree-sitter-hl-face:property ((t (:inherit font-lock-constant-face)))))

(provide 'init)
