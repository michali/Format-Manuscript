BeforeAll {

    . .\Format-Manuscript-Lib.ps1

    function Invoke-Pandoc {}
    Mock Invoke-Pandoc {}
    Mock Copy-Item {}
    Mock Get-ChildItem {  @() }
    Mock Remove-Item
    Mock New-Item
    Mock Test-Path { $true }
    Mock Write-Output { }
}


Describe 'New-Manuscript' {

    Context "When the output dir doesn't exist" {


        It "Creates an output dir if it isn't there" {
            $outputDir = ".\testdir\out"

            Mock Test-Path -ParameterFilter {  $Path -eq $outputDir }  { $false }
           
            New-Manuscript ".\testdir"
            Should -Invoke -CommandName New-Item -ParameterFilter { $ItemType -eq "Directory" -and $Path -eq $outputDir }
         }
    }

    Context "When the input dir doesn't exist" {

        It "Exits with error" {
            $inputDir = ".\testdir"

            Mock Test-Path { $false }        
    
            {New-Manuscript $inputDir} | Should -Throw          
         }
    }
}