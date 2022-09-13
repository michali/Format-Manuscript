# New-Manuscript
## Create a Word document from a collection of Markdown files

## Disclaimer
This code is provided "as is" without warranty of any kind, either express or implied, including any implied warranties of fitness for a particular purpose, merchantability, or non-infringement.

## Overview
A Powershell script that looks for markdown files in a folder structure in alphabetical order and compiles a Word document.

## Prerequisites
- The actual word document creation is done by [Pandoc](https://pandoc.org/). This needs to be installed on the machine running this script and be in the path.

- For the unit tests to run, you need Pester 5.3.0 or above.

## Versioning

The script comes with a version tagging system to track and manage different drafts of a book. This can come in handy if you want to track the last commit of the draft you are sending to your literary agent.

Major.Minor.Build

**Major**: Draft Number

**Minor**: Revision number

**Build**: Build number

Invoking the script will increment the build number of the version unless the `-NoVersion` flag is specified or there are untracked and/or unstaged files in the manuscript directory.

