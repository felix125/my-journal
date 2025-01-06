;;; my-journal.el --- Simple journal management -*- lexical-binding: t -*-
;; Copyright (C) 2025 Felix Chang
;; Author: Felix Chang <felix.profecia@gmail.com>
;; Version: 0.1
;; Package-Requires: ((emacs "27.1"))
;; Keywords: journal, notes
;; URL: https://github.com/felix125/my-journal

;;; Commentary:
;; A simple journal management package based on org-mode.
;;
;;; Code:

(defgroup my-journal nil
  "Settings for my-journal."
  :group 'org)

(defcustom my-journal-directory "~/journal/"
  "Directory for journal files."
  :type 'directory
  :group 'my-journal)

(defcustom my-journal-date-format "* %A, %d %B"
  "Format for level 1 heading date.
See `format-time-string' for formatting options."
  :type 'string
  :group 'my-journal)

(defcustom my-journal-time-format "%H%M"
  "Format for level 2 heading time.
See `format-time-string' for formatting options."
  :type 'string
  :group 'my-journal)

(defcustom my-journal-file-format "%Y-%m.org"
  "Format for journal file names.
See `format-time-string' for formatting options."
  :type 'string
  :group 'my-journal)

(defcustom my-journal-title-format "#+TITLE: Journal %Y-%m"
  "Format for journal file title.
See `format-time-string' for formatting options."
  :type 'string
  :group 'my-journal)

(defun my-journal-file-path ()
  "Return journal file path for current month."
  (let ((now (current-time)))
    (expand-file-name
     (format-time-string my-journal-file-format now)
     my-journal-directory)))

(defun my-journal-ensure-file (date)
  "Ensure journal file exists for DATE and return its path."
  (let ((file (expand-file-name
               (format-time-string my-journal-file-format date)
               my-journal-directory)))
    (make-directory (file-name-directory file) t)
    (find-file file)
    (when (= (buffer-size) 0)
      (insert (format-time-string my-journal-title-format date) "\n\n"))
    file))

(defun my-journal-ensure-date-heading (date)
  "Ensure heading exists for DATE and go to it.
Return point of heading."
  (let ((date-string (format-time-string my-journal-date-format date))
        (timestamp (format-time-string "[%Y-%m-%d %a %H:%M]")))
    (goto-char (point-min))
    (if (search-forward date-string nil t)
        (progn (beginning-of-line) (point))
      (goto-char (point-max))
      (insert "\n" date-string "\n"
              ":PROPERTIES:\n"
              ":CREATED:  " timestamp "\n"
              ":END:\n")
      (search-backward date-string))))

(defun my-journal-go-to-date (date)
  "Go to or create heading for specified DATE.
DATE should be a time value as returned by `encode-time'."
  (my-journal-ensure-file date)
  (my-journal-ensure-date-heading date))

;;;###autoload
(defun my-journal-new-entry ()
  "Create a new journal entry for current time."
  (interactive)
  (let ((file (my-journal-file-path)))
    (make-directory (file-name-directory file) t)
    (find-file file)
    (when (= (buffer-size) 0)
      (insert (format-time-string my-journal-title-format) "\n\n"))
    (my-journal-ensure-date-heading (current-time))
    (goto-char (point-max))
    (insert "** " (format-time-string my-journal-time-format))
    (just-one-space)))

;;;###autoload
(defun my-journal-go-last-entry ()
  "Open journal and move cursor to the last entry.
If no entry exists for today, create a new one."
  (interactive)
  (let ((file (my-journal-file-path)))
    (if (file-exists-p file)
        (progn
          (find-file file)
          (goto-char (point-max))
          (if (re-search-backward "^\\*\\* " nil t)
              (let ((last-entry-pos (point)))
                (beginning-of-line)
                (re-search-backward "^\\* " nil t)
                (org-show-children 1)
                (goto-char last-entry-pos))
            (my-journal-new-entry)))
      (my-journal-new-entry))))

;;;###autoload
(defun my-journal-go-current-day ()
  "Go to today's heading in journal."
  (interactive)
  (my-journal-go-to-date (current-time)))

;;;###autoload
(defun my-journal-go-previous-day ()
  "Go to previous day's heading in journal."
  (interactive)
  (let ((previous-date (time-subtract (current-time) (days-to-time 1))))
    (my-journal-go-to-date previous-date)))

;;;###autoload
(defun my-journal-go-next-day ()
  "Go to next day's heading in journal."
  (interactive)
  (let ((next-date (time-add (current-time) (days-to-time 1))))
    (my-journal-go-to-date next-date)))

;;;###autoload
(defun my-journal-calendar-open-day ()
  "Open journal entry for date at point in calendar.
If not in calendar, open calendar for selection."
  (interactive)
  (if (eq major-mode 'calendar-mode)
      (let* ((date (calendar-cursor-to-date))
             (calendar-window (get-buffer-window "*Calendar*"))
             (scratch-window (get-buffer-window "*scratch*"))
             (main-window (get-largest-window)))
        ;; 先選擇適當的視窗
        (if scratch-window
            (select-window scratch-window)
          (select-window main-window))
        ;; 打開日誌
        (my-journal-go-to-date
         (encode-time 0 0 0
                     (nth 1 date)  ; day
                     (nth 0 date)  ; month
                     (nth 2 date)  ; year
                     ))
        ;; 關閉 calendar 視窗
        (when calendar-window
          (delete-window calendar-window)))
    (calendar)))

;;;###autoload
(defun my-journal-setup ()
  "Setup journal integration with calendar."
  (define-key calendar-mode-map (kbd "RET") #'my-journal-calendar-open-day))

;;;###autoload
(add-hook 'calendar-mode-hook #'my-journal-setup)

(provide 'my-journal)
;;; my-journal.el ends here
