param(
    [Parameter(Mandatory)]
    [string]$InputDir, 
    [switch]$NoVersion
)

. .\Format-Manuscript-Lib.ps1 

New-Manuscript -InputDir $InputDir -NoVersion:$NoVersion
