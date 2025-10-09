;; early-init.el --- My early-init.el -*- lexical-binding: t -*-
;;
;; https://emacs.takeokunn.org/early-init
;;
(setq package-enable-at-startup nil)
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars . nil) default-frame-alist)
(setq inhibit-startup-message t)
(setq make-backup-files nil)
(setq auto-save-default nil)
(setq auto-save-list-file-prefix nil)
(setq create-lockfiles nil)
(setq gc-cons-threshold (* 10 128 1024 1024))
(setq garbage-collection-messages nil)
(setq read-process-output-max (* 8 1024 1024))
(setq ring-bell-function 'ignore)
(setq initial-scratch-message nil)
(setq initial-major-mode 'fundamental-mode)
(advice-add 'x-apply-session-resources :override 'ignore)
(setq inhibit-compacting-font-caches t)
(setq history-delete-duplicates t)
(setq vc-follow-symlinks t)
(setq byte-compile-warnings '(cl-functions))
