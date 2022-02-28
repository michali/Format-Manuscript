param(
    [Parameter(Mandatory)]
    [string]$InputDir, 
    [switch]$Tag
)

. .\lib.ps1 

if ($Tag -eq $true){
    New-Manuscript -InputDir $InputDir -Tag
}
else {
    New-Manuscript -InputDir $InputDir
}