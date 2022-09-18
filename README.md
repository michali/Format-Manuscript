# New-Manuscript
## Create a Word or ODT document from a collection of Markdown files

## Disclaimer
This code is provided "as is" without warranty of any kind, either express or implied, including any implied warranties of fitness for a particular purpose, merchantability, or non-infringement.

## Synopsis
Creates a Word or ODT document from a collection of Markdown files in a Git repository

## Syntax
```
New-Manuscript -InputDir [-Draft] [-Revision] [-NoVersion]
```

## Description

`-InputDir`&#9;The path to the Git repository where the manuscript files reside

`-Draft`&#9;Manuscript's draft number

`-Revision`&#9;Manuscript's revision number

`-NoVersion`&#9;Do not create a manuscript version for this run

## Overview
`New-Manuscript` is a Powershell script that looks for markdown files in alphabetical order in a folder structure and compiles a Word or ODT document. The idea behind it is that there is a version-controlled manuscript in plain text format that evolves over time, and other tools can be applied on top of it and manipulate its format before it's ready for consumption. In essence, we're applying software version control to a repository that has the code to a book with only one developer involved.

The script *can* be used for any type of document but it is intended for fiction and nonfiction books. Markdown is good for limited use cases, such as writing prose and even add inline images alongside text and. By extension, this script is not intended to support more complex document structures.


## Prerequisites
- The actual document generation is done by [Pandoc](https://pandoc.org/). This needs to be installed on the machine running this script and be in the path. Pandoc can use custom document styles by accepting a path to a Word document that it can use as a style reference, so a book can be formatted with fonts and headings other than what Pandoc would produce as a default (please see the --reference-doc=FILE section in [Pandoc's manual](https://pandoc.org/MANUAL.html#options-affecting-specific-writers)).

- Git. As a book can take months or years to finish and there can be multiple drafts, or even parallel streams of work where scenes exist in one stream but not in another, a version control system would be handy to track these changes and go back in history if needed. Git must be installed and in the path.

- For the unit tests to run, you need Pester 5.3.0 or above.

## New scenes and chapters

Typically a chapter starts with a heading style and the script assumes that this is Heading 1 (a markdown file starts with one hash symbol and a space). To insert page breaks between chapters, create a pandoc reference document and modify the heading style that you would like to start a chapter with so that a page break is inserted before the style is applied. This can be done in Word and in LibreOffice Writer.

If a chapter has multiple scenes, the script will insert a scene separator between them. This is a visual marker in a novel to denote that a new scene starts below, and it is usually a small picture or one to three asterisk characters.

## Folder structure

The folder structure doesn't need to follow a specific format as long as the files and folders are in alphabetical order. One example is as follows:

```
└───_Manuscript
    ├───Act 1
    │   ├───Chapter 1
    │   │       01.md
    │   │       02.md
    │   │       03.md
    │   │
    │   ├───Chapter 2
    │   │       01.md
    │   │       02.md
    │   │
    │   ├───Chapter 3
    │   │       01.md
    │   │       02.md
    │   │       03.md
    │   │
    │   └───Chapter 4
    │           01.md
    │
    ├───Act 2
    │   ├───Chapter 10
    │   │       01.md
    │   │       02.md
    │   │
    │   ├───Chapter 5
    │   │       01.md
    │   │       02.md
    │   │       03.md
    │   │
    │   ├───Chapter 6
    │   │       01.md
    │   │       02.md
    │   │       03.md
    │   │
    │   ├───Chapter 7
    │   │       01.md
    │   │
    │   ├───Chapter 8
    │   │       01.md
    │   │       02.md
    │   │       03.md
    │   │
    │   └───Chapter 9
    │           01.md
    │           02.md
    │
    └───Act 3
        ├───Chapter 11
        │       01.md
        │
        ├───Chapter 12
        │       01.md
        │
        ├───Chapter 13
        │       01.md
        │       02.md
        │       03.md
        │
        └───Chapter 14
                01.md
```

## Configuration
A `config.json` file in the root of the script contains the following:

```json
{
    "outputDirPart": "",
    "manuscriptDirPart": "",
    "sceneSeparatorFilePath": ""
}
```

`outputDirPart`:&#9;Path to the build output. Relative to the repository folder. This would typically be excluded from version control
`manuscriptDirPart`:&#9;Path to the top folder with the manuscript files in the Git repository. Relative to the repository folder.
`sceneSeparatorFilePath`:&#9;Path to the markdown file with the text that will act as separator between scenes. Relative to the repository folder.

All three configuration elements are mandatory.

## Versioning

The script comes with a versioning system to track and manage different drafts of a book. Book versioning would be very useful in tracking which revisions you send to your literary agent or editor.

Each time the script runs, it will create a git tag with a version number and attach it to the head commit. It will also suffix the version number of the generated document to its file name. If the `-NoVersion` switch is specified, the script will add no git tag or suffix.

### Version format
The version number consists of three parts: Major.Minor.Build. It doesn't matter what versioning system you'd like to use, I've found that the following works for me:

**Major**: Draft Number

**Minor**: Revision number

**Build**: Build number - increment with every script run unless the `-NoVersion` switch is specified

Incrementing the major number will reset the revision and build numbers to 1. Incrementing the revision number will reset the build number to 1. If both draft and revision are provided, then the rules around draft will be applied.

### *Not* versioning a generated document

Invoking the script will increment the build number of the version unless the `-NoVersion` flag is specified or there are untracked and/or unstaged files in the manuscript directory. If the `-NoVersion` switch is provided alongide `-Draft` and `-Revision`, the document will not be versioned.

## Assumptions

The chapter heading is in a file of its own.

A separate markdown file denotes a scene.

The script will inject a scene separator between scenes but not at the start and end of each chapter.
