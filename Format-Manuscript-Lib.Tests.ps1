. .\Format-Manuscript-Lib.ps1

Describe 'New-Manuscript' {

    BeforeAll {
        function Invoke-Pandoc {}
        Mock Invoke-Pandoc -MockWith {}
        Mock Copy-Item -MockWith {}
        Mock Get-ChildItem -MockWith { return @() }
        Mock Remove-Item
        Mock New-Item
        Mock Test-Path -MockWith { return $true }
    }

    Context "When the input dir doesn't exist" {
        $outputDir = "\testdir\out"
        
        Mock -CommandName Test-Path -ParameterFilter {  $Path -eq $outputDir } -MockWith { return $false }
        Mock -CommandName New-Item -ParameterFilter { $ItemType -eq "Directory" -and $Path -eq $outputDir }

        New-Manuscript "\testdir"

        It "Creates an output dir if it isn't there" {
            Assert-MockCalled New-Item -ParameterFilter { $ItemType -eq "Directory" -and $Path -eq $outputDir }
         }
    }
}