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
    Mock Get-Content {""}
    Mock Get-UnstagedUntrackedChanges {""}
    Mock Write-Warning
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
            Mock New-Version -ParameterFilter { $InputDir -eq $inputDir } { "1.0.0"} 
            New-Manuscript $inputDir
            
            Should -Invoke -CommandName Invoke-Pandoc -ParameterFilter { $outputFilePath -eq "$inputDir\out\testdir_1.0.0.docx" }
        }
    }

    Context "When specifying not to version the manuscript and there are unstaged/untracked changes" {

        It "Generates a document without a version suffix"{
            $inputDir = ".\testdir"      
            Mock Get-UnstagedUntrackedChanges { "M Changed_file.ps1" }      
            New-Manuscript $inputDir -NoVersion
            Should -Invoke -CommandName Invoke-Pandoc -ParameterFilter { $outputFilePath -eq "$inputDir\out\testdir.docx" }
        }
    }

    Context "When specifying not to version the manuscript and there are no unstaged/untracked changes" {

        It "Generates a document without a version suffix"{
            $inputDir = ".\testdir"      
            Mock Get-UnstagedUntrackedChanges { "M Changed_file.ps1" }      
            New-Manuscript $inputDir -NoVersion
            Should -Invoke -CommandName Invoke-Pandoc -ParameterFilter { $outputFilePath -eq "$inputDir\out\testdir.docx" }
        }
    }

    Context "When there are unstaged/untracked changes in git and the manuscript source code is in the same directory as the one the script is running from" {

        It "Generates a document without a version suffix"{
            $inputDir = ".\testdir"   
            Mock Get-UnstagedUntrackedChanges { "M Changed_file.ps1" }
            New-Manuscript $inputDir
            Should -Invoke -CommandName Invoke-Pandoc -ParameterFilter { $outputFilePath -eq "$inputDir\out\testdir.docx" }
        }

        It "Should return a warning that a version won't be created for the generated document"{
            $inputDir = ".\testdir"   
            Mock Get-UnstagedUntrackedChanges { "M Changed_file.ps1" }
            New-Manuscript $inputDir
            Should -Invoke -CommandName Write-Warning -ParameterFilter { $Message -eq "There are untracked stages in source control. Generated document won't be vesioned." }
        }
    }

    Context "When there are unstaged/untracked changes in git and the manuscript source code is in a directory other that the one the script is running from" {

        It "Generates a document without a version suffix"{
            $inputDir = ".\testdir"   
            $sourceControlDir = "C:\Code\Books\Book_Title"
            Mock Get-UnstagedUntrackedChanges -ParameterFilter { $sourceControlDir -eq $sourceControlDir } { "M Changed_file.ps1" }
            New-Manuscript -InputDir $inputDir -SourceControlDir $sourceControlDir
            Should -Invoke -CommandName Invoke-Pandoc -ParameterFilter { $outputFilePath -eq "$inputDir\out\testdir.docx" }
        }

        It "Should return a warning that a version won't be created for the generated document"{
            $inputDir = ".\testdir"   
            $sourceControlDir = "C:\Code\Books\Book_Title"
            Mock Get-UnstagedUntrackedChanges -ParameterFilter { $sourceControlDir -eq $sourceControlDir } { "M Changed_file.ps1" }
            New-Manuscript -InputDir $inputDir -SourceControlDir $sourceControlDir
            Should -Invoke -CommandName Write-Warning -ParameterFilter { $Message -eq "There are untracked stages in source control. Generated document won't be vesioned." }
        }
    }

    Context "When there are no unstaged/untracked changes in git and the manuscript source code is in the same directory as the one the script is running from" {

        It "Generates a document with a version suffix"{
            $inputDir = ".\testdir"   
            Mock Get-UnstagedUntrackedChanges { "" }
            Mock New-Version -ParameterFilter { $InputDir -eq $inputDir } { "1.0.0"}
            New-Manuscript $inputDir
            Should -Invoke -CommandName Invoke-Pandoc -ParameterFilter { $outputFilePath -eq "$inputDir\out\testdir_1.0.0.docx" }
        }

        It "Should not return a warning that a version won't be created for the generated document"{
            $inputDir = ".\testdir"   
            Mock Get-UnstagedUntrackedChanges { "" }
            Mock New-Version -ParameterFilter { $InputDir -eq $inputDir } { "1.0.0"}
            New-Manuscript $inputDir
            Should -Not -Invoke -CommandName Write-Warning -ParameterFilter { $Message -eq "There are untracked stages in source control. Generated document won't be vesioned." }
        }
        
    }

    Context "When there are no unstaged/untracked changes in git and the manuscript source code is in a directory other that the one the script is running from" {

        It "Generates a document with a version suffix"{
            $inputDir = ".\testdir"   
            $sourceControlDir = "C:\Code\Books\Book_Title"
            Mock Get-UnstagedUntrackedChanges -ParameterFilter { $sourceControlDir -eq $sourceControlDir } { "" }
            Mock New-Version -ParameterFilter { $InputDir -eq $inputDir } { "1.0.0"}
            New-Manuscript $inputDir -SourceControlDir $sourceControlDir
            Should -Invoke -CommandName Invoke-Pandoc -ParameterFilter { $outputFilePath -eq "$inputDir\out\testdir_1.0.0.docx" }
        }

        It "Should not return a warning that a version won't be created for the generated document"{
            $inputDir = ".\testdir"   
            $sourceControlDir = "C:\Code\Books\Book_Title"
            Mock Get-UnstagedUntrackedChanges { "" }
            Mock New-Version -ParameterFilter { $sourceControlDir -eq $sourceControlDir } { "1.0.0" }
            New-Manuscript $inputDir -SourceControlDir $sourceControlDir
            Should -Not -Invoke -CommandName Write-Warning -ParameterFilter { $Message -eq "There are untracked stages in source control. Generated document won't be vesioned." }
        }
    }
}