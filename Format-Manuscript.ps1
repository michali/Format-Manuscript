param(
    [Parameter(Mandatory)]
    [string]$InputDir, 
    [switch]$Tag
)

. .\Format-Manuscript-Lib.ps1 

if ($Tag -eq $true){
    New-Manuscript -InputDir $InputDir -Tag
}
else {
    New-Manuscript -InputDir $InputDir
}