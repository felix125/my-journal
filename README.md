# my-journal

A simple journaling package for Emacs that helps you maintain a clean and organized journal using org-mode format. Inspired by org-journal.

## Features

- Monthly org files for better organization
- Automatic date and time entries
- Calendar integration for easy navigation
- Simple and intuitive interface
- Customizable date and time formats

## Installation

### Manual Installation

Clone this repository:

```bash
git clone https://github.com/felix125/my-journal.git
```

Add to your init.el:

```
(add-to-list 'load-path "/path/to/my-journal")
(require 'my-journal)
```

### Via MELPA using use-package (Coming Soon)

```
(use-package my-journal)
```

## Usage

### Basic Commands
- `M-x my-journal-new-entry` - Create a new journal entry for current time
- `M-x my-journal-go-last-entry` - Jump to the last entry
- `M-x my-journal-go-current-day` - Go to today's entries
- `M-x my-journal-go-previous-day` - Go to previous day
- `M-x my-journal-go-next-day` - Go to next day
- `M-x calendar then RET` - Open journal entry for selected date
	
### Customization

Use `M-x customize-group RET my-journal RET` to customize all options, including:

- `my-journal-directory` - Directory for journal files (default: "~/journal/")
- `my-journal-date-format` - Format for date headings (default: "* %A, %d %B")
- `my-journal-time-format` - Format for time subheadings (default: "%H%M")
- `my-journal-file-format` - Format for monthly files (default: "%Y-%m.org")
- `my-journal-title-format` - Format for file titles (default: "#+TITLE: Journal %Y-%m")

## License

This is free and unencumbered software released into the public domain. For more information, please refer to https://unlicense.org
