param(
    [Parameter(Mandatory)]
    [string]$InputDir,
    [int]$Draft,
    [int]$Revision,
    [switch]$NoVersion
)

Import-Module -Name .\New-Manuscript

New-Manuscript -InputDir $InputDir -Draft $Draft -Revision $Revision -NoVersion:$NoVersion