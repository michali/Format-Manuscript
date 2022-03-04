param(
    [Parameter(Mandatory)]
    [string]$InputDir
)

. .\Format-Manuscript-Lib.ps1 

New-Manuscript -InputDir $InputDir