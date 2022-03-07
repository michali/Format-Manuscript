function Invoke-Pandoc {
    param (
        [Parameter(Mandatory)]
        [string]$referenceDocPath, 
        [Collections.Generic.List[String]]$files, 
        [string]$outputFilePath
    )

    & 'pandoc' $files --top-level-division=chapter --reference-doc=$referenceDocPath -o $outputFilePath
}

function Get-SavedVersion {
    param(
        [Parameter(Mandatory)]
        [string]$InputDir
    )
    $versionDir = "$InputDir\.version\version"

    if (Test-Path($versionDir)){
        return Get-Content $versionDir
    }
    return ""    
}

function New-Hidden {
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$ItemType
    )
    $item = New-Item -Path $Path -ItemType $ItemType
    $item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::Hidden
}

function Save-Version {
    param(
        [Parameter(Mandatory)]
        [string]$InputDir,
        [Parameter(Mandatory)]
        [string]$Version
    )
    $versionDir = "$InputDir\.version"
   
    if (!(Test-Path $versionDir)) {
        New-Hidden -Path $versionDir -ItemType Directory      
    }
    New-Item -Path "$versionDir\version" -ItemType File -Value $Version -Force
}

function New-Version {
    param(
		[Parameter(Mandatory)]
		[string]$InputDir,
        [string]$SourceControlDir,
        [int]$Draft,
        [int]$Revision
	)

    $unstagedUntrackedChanges = Get-UnstagedUntrackedChanges -SourceControlDir:$SourceControlDir

    $inpurDirWithoutLeadingDirectoryMarker = $InputDir.TrimStart(".\");
    $allowedUntrackedPattern = "$inpurDirWithoutLeadingDirectoryMarker/.version"

    if ($unstagedUntrackedChanges.Length -gt 0 -and ($unstagedUntrackedChanges -notlike "*$allowedUntrackedPattern*" `
     -or ($unstagedUntrackedChanges | Where-Object {$_ -notlike "*$allowedUntrackedPattern*"}).Length -gt 0)) {
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
        if ($PSBoundParameters.ContainsKey("Draft") -or $PSBoundParameters.ContainsKey("Revision")){
            if ($Draft -gt $savedDraft){
                $continue = Read-Host "Draft and Revision were both provided but the provided draft number is greater than the revision number of the previous document version. Draft number will be reset to 1. Type Y to proceed."
                
                if ($continue -ne "Y"){
                    return "";
                }
                $Revision = "1"
                $buildNumber = 1
            } else {
                if ($Revision -gt $savedRevision){
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
    
    $version = "$majorMinor.$buildNumber"

    Save-Version $InputDir $version | Out-Null
    
    return $version
}

function Assert-StartOfChapter {
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
    return git -C $SourceControlDir status --porcelain -z
}

function Set-SourceControlTag {
    param (
        [Parameter()]
        [string]$SourceControlDir,
        [string]$Tag
    )
   # return git -C $SourceControlDir status --porcelain
}

function New-Manuscript{
    param(
        [Parameter(Mandatory)]
        [string]$InputDir,
        [string]$SourceControlDir,
        [int]$Draft,
        [int]$Revision,
        [switch]$NoVersion
    )

    $config = Get-Content "$PSScriptRoot\config.json" | ConvertFrom-Json

    $InputDir = $InputDir.TrimEnd('\');
    $outputDir = "$InputDir\$($config.outputDirPart)"
    $manuscriptDir = "$InputDir\$($config.manuscriptDirPart)"
    $sceneSeparatorFilePath = "$InputDir\$($config.sceneSeparatorFilePath)"

    if (!$PSBoundParameters.ContainsKey("SourceControlDir")) {
        $SourceControlDir = ".\"
    }

    If (!(Test-Path $inputDir))
    {
        Write-Output "Path does not exist: $inputDir" -ForegroundColor Red
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

    for ($i = 0; $i -lt $manuscriptFiles.Length; $i++)
    {
        Write-Verbose "Processing $($manuscriptFiles[$i].FullName)..."

        if ($previousFile -ne '' `
        -and !(Assert-StartOfChapter($manuscriptFiles[$i].FullName)) `
        -and !(Assert-StartOfChapter($previousFile)))
        {       
            Write-Verbose "$($manuscriptFiles[$i].FullName) is the beginning of a new scene."
            $files.Add($sceneSeparatorFilePath)
        }  

        if (Assert-StartOfChapter($manuscriptFiles[$i].FullName))
        {
            Write-Verbose "$($manuscriptFiles[$i].FullName) is the beginning of a new chapter."
        }   

        $files.Add($manuscriptFiles[$i].FullName)
        $previousFile = $manuscriptFiles[$i].FullName;
    }

    $suffix = ''
    if ($NoVersion -eq $false){
        $version = New-Version -InputDir $InputDir -Draft:$Draft -Revision:$Revision -SourceControlDir:$SourceControlDir   
        
        if ($version -ne ""){
            $suffix = "_"            
            Set-SourceControlTag $SourceControlDir $version
        }
        
        $suffix = "$suffix$version"
    }

    $outputFile = (((Split-Path $inputDir -Leaf) -replace "\.\\", "") -replace "\\", "") + "$suffix.docx"

    Write-Output "Writing file to $outputDir\$outputFile"

    Invoke-Pandoc -referenceDocPath "$InputDir\..\custom-reference.docx" -files $files -outputFilePath "$outputDir\$outputFile"
}
