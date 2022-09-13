# New-Manuscript
## Create a Word or ODT document from a collection of Markdown files

## Disclaimer
This code is provided "as is" without warranty of any kind, either express or implied, including any implied warranties of fitness for a particular purpose, merchantability, or non-infringement.

## Overview
`New-Manuscript` is a Powershell script that looks for markdown files in alphabetical order in a folder structure and compiles a Word or ODT document.

The script *can* be used for any type of document but it is intended for fiction and nonfiction books. Markdown is good for limited use cases, such as writing prose and even add inline images alongside text and, by extension, this script is not intended to support more complex document structures.

## Prerequisites
- The actual document creation is done by [Pandoc](https://pandoc.org/). This needs to be installed on the machine running this script and be in the path. Pandoc can use custom document styles by accepting a path to a Word document that it can use as a style reference, so a book can be formatted with fonts and headings other than what Pandoc would produce as a default (please see the --reference-doc=FILE section in [Pandoc's manual](https://pandoc.org/MANUAL.html#options-affecting-specific-writers)).

- Git. As a book can take months or years to finish and there can be multiple drafts, or even parallel streams of work where scenes exist in one stream but not in another, a version control system would be handy to track these changes and go back in history if needed. Git must be installed and in the path.

- For the unit tests to run, you need Pester 5.3.0 or above.

## Versioning

The script comes with a versioning system to track and manage different drafts of a book. A version would be very useful in tracking which revisions you send to your literary agent or publisher.

A git tag is created with the version number and attached to the head commit. Also, the version number of the generated document is suffixed to its file name.

### Version format

Major.Minor.Build

**Major**: Draft Number

**Minor**: Revision number

**Build**: Build number

### *Not* versioning a generated document

Invoking the script will increment the build number of the version unless the `-NoVersion` flag is specified or there are untracked and/or unstaged files in the manuscript directory.

