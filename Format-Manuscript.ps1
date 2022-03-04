param(
    [Parameter(Mandatory)]
    [string]$InputDir,
    [string]$sourceControlDir,
    [switch]$NoVersion
)

. .\Format-Manuscript-Lib.ps1 

New-Manuscript -InputDir $InputDir -SourceControlDir $sourceControlDir -NoVersion:$NoVersion 
