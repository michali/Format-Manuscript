BeforeAll {

    . .\Format-Manuscript-Lib.ps1

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

    Context "When Checking the manuscript files for scenes" {
        
        It "Injects a scene separator between scenes based on the markdown in the files" {
            
            $inputDir = ".\testdir"            
            Mock Get-ChildItem -ParameterFilter {  $Path -eq "$inputDir\_Manuscript" } -MockWith { @([PSCustomObject]@{Name="scene1.md"; FullName=".\testdir\_Manuscript\scene1.md"},[PSCustomObject]@{Name="scene2.md"; FullName=".\testdir\_Manuscript\scene2.md"} ) }
            Mock Get-Content -ParameterFilter { $Path -eq ".\testdir\_Manuscript\scene1.md" } { "" }
            Mock Get-Content -ParameterFilter { $Path -eq ".\testdir\_Manuscript\scene2.md" } { "" }

            New-Manuscript $inputDir
            
            Should -Invoke -CommandName Invoke-Pandoc -ParameterFilter { $files -ccontains ".\testdir\_Manuscript\scene1.md" }
            Should -Invoke -CommandName Invoke-Pandoc -ParameterFilter { $files -ccontains ".\testdir\..\Templates\Scene separator.md" }
            Should -Invoke -CommandName Invoke-Pandoc -ParameterFilter { $files -ccontains ".\testdir\_Manuscript\scene2.md" }
        }
    }
}