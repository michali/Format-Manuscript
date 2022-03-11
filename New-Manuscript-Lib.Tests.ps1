BeforeAll {

    . $PSScriptRoot\New-Manuscript-Lib.ps1

    # Default mocks of commands so the script does not cross application boundaries
    # when tests are running
    Mock New-Item
    Mock Test-Path { $true }
    Mock Write-Output { }
    Mock Get-Content {""}
    Mock Get-UnstagedUntrackedChanges {""}
    Mock Write-Warning
    Mock Get-Content -ParameterFilter {$Path -eq "$PSScriptRoot\config.json"} { "{""outputDirPart"": ""out"", ""manuscriptDirPart"": ""_Manuscript"", ""sceneSeparatorFilePath"": ""Templates\\Scene separator.md""}" }
}

Describe 'New-Manuscript' {

    BeforeAll {    
        Mock Invoke-Pandoc {}     
        Mock Copy-Item {}   
        Mock Get-ChildItem {  @() } 
        Mock New-Version {""}
        Mock Save-Version { }
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
            Mock New-Version -ParameterFilter { $InputDir -eq $inputDir } { "1.0.0" } 
            New-Manuscript $inputDir
            
            Should -Invoke -CommandName Invoke-Pandoc -ParameterFilter { $outputFilePath -eq "$inputDir\out\testdir_1.0.0.docx" }
        }
    }

    Context "When specifying not to version the manuscript" {

        It "Does not create a version"{
            $inputDir = ".\testdir"      
            New-Manuscript $inputDir -NoVersion
            Should -Invoke -CommandName Invoke-Pandoc -ParameterFilter { $outputFilePath -eq "$inputDir\out\testdir.docx" }
        }
    }   
        
    Context "When a version is created" {

        It "Sets the version"{
            Mock New-Version { "1.0.0" } 

            New-Manuscript ".\testdir"

            Should -Invoke -CommandName Save-Version -ParameterFilter {$InputDir -eq ".\testdir" -and $Version -eq "1.0.0" }
        }
    }
    
    Context "When a version is not created" {

        It "Does not tag the head of the source control"{
            Mock New-Version { "" } 

            New-Manuscript ".\testdir"

            Should -Invoke -CommandName Save-Version -Exactly 0
        }

        It "Ends the filename with the input dir's name"{
            $inputDir = ".\testdir"    

            Mock New-Version { "" } 

            New-Manuscript $inputDir
            Should -Invoke -CommandName Invoke-Pandoc -ParameterFilter { $outputFilePath -eq "$inputDir\out\testdir.docx" }
        }
    } 

    Context "When a directory with the manuscript source files is not provided" {

        It "Should use the current directory as the source control directory"{
            Mock New-Version { "1.0.0" } 

            New-Manuscript ".\testdir"

            Should -Invoke -CommandName Save-Version -ParameterFilter {$InputDir -eq ".\testdir" -and $Version -eq "1.0.0" }
        }
    } 
}

Describe "Versioning" {  
    
    BeforeAll {        
        Mock Read-Host {"Y"}
    }

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

            Mock Get-UnstagedUntrackedChanges { "" }
            Mock Get-SavedVersion {""}

            New-Version ".\testdir" | Should -Be "0.1.1"
        }
    }

    Context "When the Draft and Revision arguments are specified"{
        It "Should create a version number in the format of Draft.Revision.1 where 1 is the build number"{

            Mock Get-SavedVersion {""}

            New-Version ".\testdir" -Draft 1 -Revision 0 | Should -Be "1.0.1"
        }
    }

    Context "When call to versioning is executed thrice"{
        It "Draft and Revision numbers should remain the same and the build number should increment" {

            $Script:mockCounter = 0; 
            Mock Get-SavedVersion {
                switch($Script:mockCounter){
                    0 { "" }
                    1 { "0.1.1" }
                    Default { "0.1.2" }
                }
                $Script:mockCounter++
            }
            
            New-Version ".\testdir" | Should -Be "0.1.1"
            New-Version ".\testdir" | Should -Be "0.1.2"
            New-Version ".\testdir" | Should -Be "0.1.3"
        }
    }

    Context "When call to versioning is executed with specified draft number and revision number"{
        It "Draft and Revision numbers should remain the same and the build number should increment" {

            $Script:mockCounter = 0; 
            Mock Get-SavedVersion {
                switch($Script:mockCounter){
                    0 { "" }
                    1 { "1.1.1" }
                    Default { "1.1.2" }
                }
                $Script:mockCounter++
            }
            
            New-Version ".\testdir" -Draft 1 -Revision 1 | Should -Be "1.1.1"
            New-Version ".\testdir" -Draft 1 -Revision 1 | Should -Be "1.1.2"
            New-Version ".\testdir" -Draft 1 -Revision 1 | Should -Be "1.1.3"
        }
    }

    Context "When revision number is incremented"{
        It "The build number should reset to 1" { 

            $Script:mockCounter = 0; 
            Mock Get-SavedVersion {
                switch($Script:mockCounter){
                    0 { "" }
                    1 { "1.1.1" }
                    Default { "1.1.2" }
                }
                $Script:mockCounter++
            }
            
            New-Version ".\testdir" -Draft 1 -Revision 1 | Should -Be "1.1.1"
            New-Version ".\testdir" -Draft 1 -Revision 1 | Should -Be "1.1.2"
            New-Version ".\testdir" -Draft 1 -Revision 2 | Should -Be "1.2.1"
        }
    }

    Context "When call to versioning is executed only with Draft and Draft is greater than the previous draft number"{
        It "Should reset Revision to 1 and Build to 1" {
            $Script:mockCounter = 0; 

            Mock Get-SavedVersion { "1.1.1" }                

            New-Version ".\testdir" | Should -Be "1.1.2"
            New-Version ".\testdir" -Draft 2 | Should -Be "2.1.1"
        }
    }

    Context "When call to versioning is executed with Draft and Revision, and Draft is greater than the previous draft number"{
        It "Should reset Revision to 1 and Build to 1, give a prompt where Y ignore the provided Revision in the script" {
            $Script:mockCounter = 0; 

            Mock Get-SavedVersion { "1.5.1" }                
            Mock Read-Host { "Y" }

            $version = New-Version ".\testdir" -Draft 2 -Revision 6

            Should -Invoke Read-Host -ParameterFilter { $Prompt -like "Draft and Revision*"}
            $version | Should -Be "2.1.1"
        }
    }

    Context "When call to versioning is executed with Draft and Revision, and Draft is greater than the previous draft number"{
        It "Should reset Revision to 1 and Build to 1, give a prompt where no would exit with no version" {
            $Script:mockCounter = 0; 

            Mock Get-SavedVersion { "1.5.1" }                
            Mock Read-Host { "N" }

            $version = New-Version ".\testdir" -Draft 2 -Revision 6

            Should -Invoke Read-Host -ParameterFilter { $Prompt -like "Draft and Revision*"}
            $version | Should -Be ""
        }
    }

    Context "When only a Revision is provided"{
        It "The draft number should not change" {
            $Script:mockCounter = 0; 

            Mock Get-SavedVersion { "1.5.1" }                
            
            $version = New-Version ".\testdir" -Revision 6

            $version | Should -BeLike "1.6*"
        }
    }

    Context "When only a Revision is provided and it is greater than the previous revision"{
        It "The build number should reset" {
            $Script:mockCounter = 0; 

            Mock Get-SavedVersion { "1.5.1" }

            $version = New-Version ".\testdir" -Revision 6

            $version | Should -BeLike "*6.1"
        }
    }
}

Describe "Get-SavedVersion" {

    Context "When version data doesn't exist in the system" {
        It "Should return empty" {

            Mock Get-LatestVersion {""}

            Get-SavedVersion -InputDir ".\" | should -Be ""            
        }
    }

    Context "When version data doesn't exist in the system" {
        It "Should return empty" {

            Mock Get-LatestVersion {"v1.0"}

            Get-SavedVersion -InputDir ".\" | should -Be "1.0"            
        }
    }
}