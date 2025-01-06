;;; my-journal.el --- Simple journaling with org-mode -*- lexical-binding: t -*-

;; Copyright (C) 2025 Felix Chang

;; Author: Felix Chang <felix.profecia@gmail.com>
;; Version: 0.1
;; Package-Requires: ((emacs "27.1") (org "9.3"))
;; Keywords: convenience, calendar, journal
;; URL: https://github.com/felix125/my-journal

;; This is free and unencumbered software released into the public domain.
;; See https://unlicense.org

;;; Commentary:

;; my-journal is a simple journaling package that helps you maintain a clean
;; and organized journal using org-mode format.  It provides:
;;
;; - Monthly org files for better organization
;; - Automatic date and time entries
;; - Calendar integration for easy navigation
;; - Simple and intuitive interface
;; - Customizable date and time formats
;;
;; Basic usage:
;;
;; M-x my-journal-new-entry     Create a new journal entry
;; M-x my-journal-go-last-entry Go to the last entry
;; M-x calendar RET             Open journal for selected date
;;
;; For more information, see the README.md file.

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
DATE should be a time value as returned by `encode-time'.

This function ensures that:
1. The monthly journal file exists
2. The day heading exists
3. The cursor is positioned at the heading"
  (my-journal-ensure-file date)
  (my-journal-ensure-date-heading date))

;;;###autoload
(defun my-journal-new-entry ()
  "Create a new journal entry for current time.

This command will:
1. Open or create the current month's journal file
2. Create a heading for today if it doesn't exist
3. Add a new time-stamped entry under today's heading
4. Position cursor ready for writing the entry"
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
If no entry exists for today, create a new one.

When executed, this command will:
1. Open the current month's journal file
2. Navigate to the most recent entry
3. Expand the entry's parent heading
4. If no entry exists, create a new one"
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
  "Go to today's heading in journal.

Opens the current month's journal file and moves
cursor to today's date heading, creating it if necessary."
  (interactive)
  (my-journal-go-to-date (current-time)))

;;;###autoload
(defun my-journal-go-previous-day ()
  "Go to previous day's heading in journal.

Opens the appropriate journal file and moves cursor to
the previous day's heading, creating it if necessary."
  (interactive)
  (let ((previous-date (time-subtract (current-time) (days-to-time 1))))
    (my-journal-go-to-date previous-date)))

;;;###autoload
(defun my-journal-go-next-day ()
  "Go to next day's heading in journal.

Opens the appropriate journal file and moves cursor to
the next day's heading, creating it if necessary."
  (interactive)
  (let ((next-date (time-add (current-time) (days-to-time 1))))
    (my-journal-go-to-date next-date)))

;;;###autoload
(defun my-journal-calendar-open-day ()
  "Open journal entry for date at point in calendar.
If not in calendar, open calendar for selection.

When in calendar:
1. Takes the date at point
2. Opens the appropriate journal file
3. Creates the date heading if necessary
4. Closes the calendar window

When not in calendar:
1. Opens the calendar for date selection"
  (interactive)
  (if (eq major-mode 'calendar-mode)
      (let* ((date (calendar-cursor-to-date))
             (calendar-window (get-buffer-window "*Calendar*"))
             (scratch-window (get-buffer-window "*scratch*"))
             (main-window (get-largest-window)))
        ;; Automatically select the appropriate window
        (if scratch-window
            (select-window scratch-window)
          (select-window main-window))
        ;; Open calendar window
        (my-journal-go-to-date
         (encode-time 0 0 0
                     (nth 1 date)  ; day
                     (nth 0 date)  ; month
                     (nth 2 date)  ; year
                     ))
        ;; Close calendar window
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
