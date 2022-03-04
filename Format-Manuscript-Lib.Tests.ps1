BeforeAll {

    . .\Format-Manuscript-Lib.ps1

    # Default mocks of commands so the script does not cross application boundaries
    # when tests are running
    Mock Invoke-Pandoc {}
    Mock Copy-Item {}
    Mock Get-ChildItem {  @() }
    Mock Remove-Item
    Mock New-Item
    Mock Test-Path { $true }
    Mock Write-Output { }
    Mock Get-Content -ParameterFilter {$Path -eq ".\config.json"} { "{""outputDirPart"": ""out"", ""manuscriptDirPart"": ""_Manuscript"", ""sceneSeparatorFilePath"": ""Templates\\Scene separator.md""}" }
}

Describe 'New-Manuscript' {

    Context "When the output dir doesn't exist" {

        It "Creates the output dir" {
            $outputDir = ".\testdir\out"

            Mock Test-Path -ParameterFilter {  $Path -eq $outputDir }  { $false }
           
            New-Manuscript ".\testdir"
            Should -Invoke -CommandName New-Item -ParameterFilter { $ItemType -eq "Directory" -and $Path -eq $outputDir }
         }
    }

    Context "When the input dir doesn't exist" {

        It "Exits with error" {
            $inputDir = ".\testdir"

            Mock Test-Path -ParameterFilter {  $Path -eq $inputDir }  { $false }     
    
            {New-Manuscript $inputDir} | Should -Throw          
         }
    }

    Context "When Checking the manuscript files" {
        
        It "Injects a scene separator between scenes based on the markdown in the files" {            
            $inputDir = ".\testdir"            
            Mock Get-ChildItem -ParameterFilter {  $Path -eq "$inputDir\_Manuscript" } -MockWith { @([PSCustomObject]@{Name="scene1.md"; FullName="$inputDir\_Manuscript\scene1.md"},[PSCustomObject]@{Name="scene2.md"; FullName="$inputDir\_Manuscript\scene2.md"} ) }
            Mock Get-Content -ParameterFilter { $Path -eq "$inputDir\_Manuscript\scene1.md" } { "" }
            Mock Get-Content -ParameterFilter { $Path -eq "$inputDir\_Manuscript\scene2.md" } { "" }

            New-Manuscript $inputDir
            
            Should -Invoke -CommandName Invoke-Pandoc -ParameterFilter { $files[0] -eq "$inputDir\_Manuscript\scene1.md" }
            Should -Invoke -CommandName Invoke-Pandoc -ParameterFilter { $files[1] -eq "$inputDir\Templates\Scene separator.md" }
            Should -Invoke -CommandName Invoke-Pandoc -ParameterFilter { $files[2] -eq "$inputDir\_Manuscript\scene2.md" }
        }

        It "Creates a draft in the expected path" {            
            $inputDir = ".\testdir"            
            Mock Get-ChildItem -ParameterFilter {  $Path -eq "$inputDir\_Manuscript" } -MockWith { @([PSCustomObject]@{Name="scene1.md"; FullName="$inputDir\_Manuscript\scene1.md"},[PSCustomObject]@{Name="scene2.md"; FullName="$inputDir\_Manuscript\scene2.md"} ) }
            Mock Get-Content -ParameterFilter { $Path -eq "$inputDir\_Manuscript\scene1.md" } { "" }
            Mock Get-Content -ParameterFilter { $Path -eq "$inputDir\_Manuscript\scene2.md" } { "" }

            New-Manuscript $inputDir
            
            Should -Invoke -CommandName Invoke-Pandoc -ParameterFilter { $outputFilePath -eq "$inputDir\out\testdir.docx" }
        }
    }
}