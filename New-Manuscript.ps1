param(
    [Parameter(Mandatory)]
    [string]$InputDir,
    [string]$SourceControlDir,
    [int]$Draft,
    [int]$Revision,
    [switch]$NoVersion
)

. $PSScriptRoot\New-Manuscript-Lib.ps1 

New-Manuscript -InputDir $InputDir -SourceControlDir:$SourceControlDir -Draft $Draft -Revision $Revision -NoVersion:$NoVersion 