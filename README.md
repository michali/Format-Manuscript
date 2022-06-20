# New-Manuscript
## Create a Word document from a collection of Markdown files and incrementally suffix the file with a version number

## Disclaimer
This code is provided "as is" without warranty of any kind, either express or implied, including any implied warranties of fitness for a particular purpose, merchantability, or non-infringement.

## Overview
A Powershell script that scrapes a folder for markdown files and creates a 

## Prerequisites
The actual word document creation is done by [Pandoc](https://pandoc.org/). This needs to be installed on the machine running this script and be in the path.


## Versioning

Major.Minor.Build

**Major**: Draft Number

**Minor**: Revision number

**Build**: Build number 

Invoking the script will build a new version of the generated document unless the `-NoVersion` flag is specified or there are untracked and/or unstaged files in the manuscript directory.

