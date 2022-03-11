param(
    [Parameter(Mandatory)]
    [string]$InputDir,
    [int]$Draft,
    [int]$Revision,
    [switch]$NoVersion
)

. $PSScriptRoot\New-Manuscript-Lib.ps1 

New-Manuscript @PSBoundParameters