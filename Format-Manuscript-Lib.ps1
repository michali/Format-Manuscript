function Invoke-Pandoc {
    param (
        [Parameter(Mandatory)]
        [string]$referenceDocPath, 
        [Collections.Generic.List[String]]$files, 
        [string]$outputFilePath
    )

    & 'pandoc' $files --top-level-division=chapter --reference-doc=$referenceDocPath -o $outputFilePath
}

function New-Version {
    param(
		[Parameter(Mandatory)]
		[string]$InputDir,
        [int]$Draft,
        [int]$Revision
	)

    $hasUntrackedChanges = Get-UnstagedUntrackedChanges $sourceControlDir
    if ($hasUntrackedChanges.Length -gt 0){
        Write-Warning "There are untracked stages in source control. Generated document won't be vesioned."
        return ""
    }

    # if ($PSBoundParameters.ContainsKey("Draft") -and $PSBoundParameters.ContainsKey("Revision")){
    #     $majorMinor = "$Draft.$Revision"
    # }
    # else {
       $majorMinor = "0.1"
    # }

    $buildNumber = "1"

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
    
    #Get version and increase the build number
    # $versionPart = Get-Content $majorMinorFilePath
    # $buildNumber = [int](Get-Content $buildFilePath) + 1

    return "$majorMinor.$buildNumber"    
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
        [string]$sourceControlDir
    )
    return git status --porcelain
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
        $version = New-Version -InputDir $InputDir -Draft:$Draft -Revision:$Revision
        
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
