function Invoke-Pandoc {
    param (
        [Parameter(Mandatory)]
        [string]$referenceDocPath, 
        [Collections.Generic.List[String]]$files, 
        [string]$outputFilePath
    )

    & 'pandoc' $files --top-level-division=chapter --reference-doc=$referenceDocPath -o $outputFilePath
}

function Get-LatestVersionTag {
    return git for-each-ref --sort=-taggerdate --count=1  refs/tags/v*
}

function Get-SavedVersion {
    param(
        [Parameter(Mandatory)]
        [string]$InputDir
    )
     
    $version = Get-LatestVersionTag $InputDir

    if ($version) {
        $mc = [regex]::matches($version, "v\d\.\d\.\d")
        return $mc.groups[0].value.TrimStart("v")
    }

    return ""
}

function New-Version {
    param(
		[Parameter(Mandatory)]
		[string]$InputDir,
        [int]$Draft,
        [int]$Revision
	)

    $unstagedUntrackedChanges = Get-UnstagedUntrackedChanges -SourceControlDir $InputDir

    if ($unstagedUntrackedChanges.Length -gt 0) {
        Write-Warning "There are untracked stages in source control. Generated document won't be vesioned."
        return ""
    }

    $savedVersionParts = (Get-SavedVersion $InputDir).Split('.')

    if ($savedVersionParts.Length -eq 1){
        if ($PSBoundParameters.ContainsKey("Draft") -and $PSBoundParameters.ContainsKey("Revision")){
            $majorMinor = "$Draft.$Revision"
        }
        else {
           $majorMinor = "0.1"
        }
    
        $buildNumber = 1   
    }
    else {
        $savedDraft = $savedVersionParts[0]
        $savedRevision = $savedVersionParts[1]
        $savedBuild = $savedVersionParts[2]

        if ($PSBoundParameters.ContainsKey("Draft") -and $PSBoundParameters.ContainsKey("Revision")){
            if ($Draft -gt $savedDraft){
                $continue = Read-Host "Draft and Revision were both provided but the provided draft number is greater than the draft number of the previous document version. Revision number will be reset to 1. Type Y to proceed."
                
                if ($continue -ne "Y"){
                    return "";
                }
            }
        }

        if ($PSBoundParameters.ContainsKey("Draft") -or $PSBoundParameters.ContainsKey("Revision")){            
            if (!$PSBoundParameters.ContainsKey("Draft")){
                $Draft = $savedDraft   
                if ($Revision -gt $savedRevision){
                    $buildNumber = 1
                }             
            }
            else {
                if ($Draft  -gt $savedDraft) {
                    $Revision = 1
                    $buildNumber = 1
                }
                elseif ($Revision -gt $savedRevision){
                    $buildNumber = 1
                }
                else {
                    $buildNumber = [int]$savedBuild + 1
                }
            }
            $majorMinor = "$Draft.$Revision"
        }
        else {
            $majorMinor = "$($savedDraft).$($savedRevision)"
            $buildNumber = [int]$savedBuild + 1
        }
    }
    
    return "$majorMinor.$buildNumber"
}

function Assert-IsChapterHeading {
	param(
		[Parameter()]
		[string] $filePath
	)

	return ((Get-Content $filePath) -join "").StartsWith("# ")
}

function Get-UnstagedUntrackedChanges {
    param (
        [Parameter()]
        [string]$SourceControlDir
    )
    return git -C ($SourceControlDir -replace "\\", "/") status --porcelain
}

function Set-SourceControlTag {
    param (
        [Parameter(Mandatory)]
        [string]$SourceControlDir,
        [Parameter(Mandatory)]
        [string]$Tag,
        [Parameter(Mandatory)]
        [string]$Message
    )

    git -C $SourceControlDir tag -a $Tag -m $Message
}

function Save-Version {
    param (
        [Parameter(Mandatory)]
        [string]$InputDir,
        [Parameter(Mandatory)]
        [string]$Version
    )

    Set-SourceControlTag $InputDir "v$version" "Version $version"
}

function New-Manuscript{
    param(
        [Parameter(Mandatory)]
        [string]$InputDir,
        [int]$Draft,
        [int]$Revision,
        [switch]$NoVersion
    )

    $config = Get-Content "$PSScriptRoot\config.json" | ConvertFrom-Json

    $InputDir = $InputDir.TrimEnd('\');
    $outputDir = "$InputDir\$($config.outputDirPart)"
    $manuscriptDir = "$InputDir\$($config.manuscriptDirPart)"
    $sceneSeparatorFilePath = "$InputDir\$($config.sceneSeparatorFilePath)"

    If (!(Test-Path $inputDir))
    {
        Write-Error "Path does not exist: $inputDir" -ForegroundColor Red
        throw
    }
    
    If (!(Test-Path $outputDir))
    {
        New-Item -ItemType Directory -Path $outputDir
    }

    Write-Output "Input Dir: $inputDir"
    Write-Output "Output Dir: $outputDir"   

    $manuscriptFiles = Get-ChildItem $manuscriptDir -rec | Where-Object { $_.Name.EndsWith(".md") }
    $files = New-Object Collections.Generic.List[String]
    $previousFile = ''

    for ($i = 0; $i -lt $manuscriptFiles.Count; $i++)
    {
        Write-Verbose "Processing $($manuscriptFiles[$i].FullName)..."

        if ($previousFile -ne '' `
        -and !(Assert-IsChapterHeading($manuscriptFiles[$i].FullName)) `
        -and !(Assert-IsChapterHeading($previousFile)))
        {       
            Write-Verbose "$($manuscriptFiles[$i].FullName) is the beginning of a new scene."
            $files.Add($sceneSeparatorFilePath)
        }  

        if (Assert-IsChapterHeading($manuscriptFiles[$i].FullName))
        {
            Write-Verbose "$($manuscriptFiles[$i].FullName) is the beginning of a new chapter."
        }   

        $files.Add($manuscriptFiles[$i].FullName)
        $previousFile = $manuscriptFiles[$i].FullName;
    }

    $suffix = ''
    if ($NoVersion -eq $false){
        $version = New-Version -InputDir $InputDir -Draft $Draft -Revision $Revision
        
        if ($version -ne ""){
            $suffix = "_"            
            Save-Version $InputDir $version
        }
        
        $suffix = "$suffix$version"
    }

    $outputFile = (((Split-Path $inputDir -Leaf) -replace "\.\\", "") -replace "\\", "") + "$suffix.docx"

    Write-Output "Writing file to $outputDir\$outputFile"

    Invoke-Pandoc -referenceDocPath "$InputDir\..\custom-reference.docx" -files $files -outputFilePath "$outputDir\$outputFile"
}

Export-ModuleMember -Function New-Manuscript