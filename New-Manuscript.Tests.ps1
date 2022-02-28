Describe 'New-Manuscript' {

    BeforeAll {
        Mock -CommandName "Test-Path" -ParameterFilter { $Path -eq $inputDir} -MockWith { return $true }
    }

    Context "When the output dir doesn't exist" {
        $inputDir = '.\Manuscript'
        $outputDir = "$inputDir\out"
        
        Mock -CommandName "Test-Path" -ParameterFilter {  $Path -eq $outputDir } -MockWith { return $false }
        Mock -CommandName "New-Item" -ParameterFilter { $ItemType -eq "Directory" -and $Path -eq $outputDir }

        .\New-Manuscript.ps1 -InputDir $inputDir
    }

    It "Creates an output dir if it isn't there" {
       Assert-MockCalled -CommandName 'New-Item'
    }
}