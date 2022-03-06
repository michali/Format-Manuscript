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

    BeforeAll {        
        Mock New-Version {""}
    }

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

    Context "When specifying not to version the manuscript" {

        It "Does not create a version"{
            $inputDir = ".\testdir"      
            Mock Get-UnstagedUntrackedChanges { "M Changed_file.ps1" }      
            New-Manuscript $inputDir -NoVersion
            Should -Invoke -CommandName Invoke-Pandoc -ParameterFilter { $outputFilePath -eq "$inputDir\out\testdir.docx" }
        }
    }
}

Describe "Versioning" {    

    Context "When there are unstaged/untracked changes" {

        It "Should not create a default version"{   
            Mock Get-UnstagedUntrackedChanges { "M Changed_file.ps1" }   

            New-Version ".\testdir" | Should -Be ""
        }

        It "Should return a warning that a version won't be created for the generated document"{
            Mock Get-UnstagedUntrackedChanges { "M Changed_file.ps1" }

            New-Version ".\testdir" 

            Should -Invoke -CommandName Write-Warning -ParameterFilter { $Message -eq "There are untracked stages in source control. Generated document won't be vesioned." }
        }
    }    

    Context "When there are no unstaged/untracked changes" {

        It "Should create a default version"{
            $inputDir = ".\testdir"   
            Mock Get-UnstagedUntrackedChanges { "" }
            Mock Get-SavedVersion {""}

            New-Version $inputDir | Should -Be "0.1.1"
        }
    }

    Context "When the Draft and Revision arguments are specified"{
        It "Should create a version number in the format of Draft.Revision.1 where 1 is the build number"{
            $inputDir = ".\testdir"
            Mock Get-SavedVersion {""}

            New-Version $inputDir -Draft 1 -Revision 0 | Should -Be "1.0.1"
        }
    }

    Context "When call to versioning is executed thrice"{
        It "Draft and Revision numbers should remain the same and the build number should increment" {
            $inputDir = ".\testdir"  

            $Script:mockCounter = 0; 
            Mock Get-SavedVersion {
                switch($Script:mockCounter){
                    0 { "" }
                    1 { "0.1.1" }
                    Default { "0.1.2" }
                }
                $Script:mockCounter++
            }
            
            New-Version $inputDir | Should -Be "0.1.1"
            New-Version $inputDir | Should -Be "0.1.2"
            New-Version $inputDir | Should -Be "0.1.3"
        }
    }

    Context "When call to versioning is executed with specified draft number and revision number"{
        It "Draft and Revision numbers should remain the same and the build number should increment" {
            $inputDir = ".\testdir"  

            $Script:mockCounter = 0; 
            Mock Get-SavedVersion {
                switch($Script:mockCounter){
                    0 { "" }
                    1 { "1.1.1" }
                    Default { "1.1.2" }
                }
                $Script:mockCounter++
            }
            
            New-Version $inputDir -Draft 1 -Revision 1 | Should -Be "1.1.1"
            New-Version $inputDir -Draft 1 -Revision 1 | Should -Be "1.1.2"
            New-Version $inputDir -Draft 1 -Revision 1 | Should -Be "1.1.3"
        }
    }

    Context "When revision number is incremented"{
        It "The build number should reset to 1" {
            $inputDir = ".\testdir"  

            $Script:mockCounter = 0; 
            Mock Get-SavedVersion {
                switch($Script:mockCounter){
                    0 { "" }
                    1 { "1.1.1" }
                    Default { "1.1.2" }
                }
                $Script:mockCounter++
            }
            
            New-Version $inputDir -Draft 1 -Revision 1 | Should -Be "1.1.1"
            New-Version $inputDir -Draft 1 -Revision 1 | Should -Be "1.1.2"
            New-Version $inputDir -Draft 1 -Revision 2 | Should -Be "1.2.1"
        }
    }

    Context "When call to versioning is executed thrice"{
        It "Generated version is persisted in the system" {
            $inputDir = ".\testdir"  

            $Script:mockCounter = 0; 
            Mock Get-SavedVersion {
                switch($Script:mockCounter){
                    0 { "" }
                    1 { "0.1.1" }
                    Default { "0.1.2" }
                }
                $Script:mockCounter++
            }

            Mock Save-Version {}
            
            New-Version $inputDir
            New-Version $inputDir
            New-Version $inputDir

            Should -Invoke Save-Version -ParameterFilter { $Version -eq "0.1.1" }
            Should -Invoke Save-Version -ParameterFilter { $Version -eq "0.1.2" }
            Should -Invoke Save-Version -ParameterFilter { $Version -eq "0.1.3" }
        }
    }

    # Mock Get-Content -ParameterFilter { $Path -eq "$inputDir\.version\majorMinor" } {
    #     if ($Script:mockCounter -eq 0) {"1.1"} else {"1.1"}
    # }

}