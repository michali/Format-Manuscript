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

}

function Save-Version {
    param(
        [Parameter(Mandatory)]
        [string]$Version
    )

    # Create structure if it doesn't exist
    # $versionDir = "$InputDir\.version"
    # $buildFilePath = "$versionDir\build"
    # $majorMinorFilePath = "$versionDir\majorMinor"

    # if (!(Test-Path $versionDir)) {
    #     Write-Output "Creating version folder"
    #     $vd = New-Item -Path $versionDir -ItemType Directory
    #     $vd.Attributes = $vd.Attributes -bor [System.IO.FileAttributes]::Hidden
    # }
    
    # if (!(Test-Path $buildFilePath)) {
    #     Write-Output "Creating version file"
    #     $v = New-Item -Path $buildFilePath -ItemType File -Value "0"
    #     $v.Attributes = $v.Attributes -bor [System.IO.FileAttributes]::Hidden
    #     $v.Attributes = $v.Attributes -bor [System.IO.FileAttributes]::ReadOnly
    # }

    # if (!(Test-Path $majorMinorFilePath)) {
    #     Write-Output "Creating version set file"
    #     New-Item -Path $majorMinorFilePath -ItemType File -Value $majorMinor
    # }
}

function New-Version {
    param(
		[Parameter(Mandatory)]
		[string]$InputDir,
        [string]$SourceControlDir,
        [int]$Draft,
        [int]$Revision
	)

    $hasUntrackedChanges = Get-UnstagedUntrackedChanges -SourceControlDir:$SourceControlDir

    if ($hasUntrackedChanges.Length -gt 0){
        Write-Warning "There are untracked stages in source control. Generated document won't be vesioned."
        return ""
    }

    $savedVersionParts = (Get-SavedVersion).Split('.')

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

    Save-Version $version    

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
    return git -C $SourceControlDir status --porcelain
}

function New-Manuscript{
    param(
        [Parameter(Mandatory)]
        [string]$InputDir,
        [string]$sourceControlDir,
        [int]$Draft,
        [int]$Revision,
        [switch]$NoVersion
    )

    $config = Get-Content .\config.json | ConvertFrom-Json

    $InputDir = $InputDir.TrimEnd('\');
    $outputDir = "$InputDir\$($config.outputDirPart)"
    $manuscriptDir = "$InputDir\$($config.manuscriptDirPart)"
    $sceneSeparatorFilePath = "$InputDir\$($config.sceneSeparatorFilePath)"

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
        $suffix = "_"
        $version = New-Version -InputDir $InputDir -Draft:$Draft -Revision:$Revision -SourceControlDir:$sourceControlDir
        
        if ($PSBoundParameters.ContainsKey("Draft") -and $PSBoundParameters.ContainsKey("Revision")){
            $version = "$Draft.$Revision.0"
        }

        $suffix = "$suffix$version"
    }

    $outputFile = (((Split-Path $inputDir -Leaf) -replace "\.\\", "") -replace "\\", "") + "$suffix.docx"

    Write-Output "Writing file to $outputDir\$outputFile"
    Write-Debug "$outputDir\$outputFile"
    Invoke-Pandoc -referenceDocPath "$InputDir\..\custom-reference.docx" -files $files -outputFilePath "$outputDir\$outputFile"
}
