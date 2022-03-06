param(
    [Parameter(Mandatory)]
    [string]$InputDir,
    [string]$sourceControlDir,
    [int]$Draft,
    [int]$Revision,
    [switch]$NoVersion
)

. .\Format-Manuscript-Lib.ps1 

New-Manuscript -InputDir $InputDir -SourceControlDir $sourceControlDir -Draft $Draft -Revision $Revision -NoVersion:$NoVersion 
