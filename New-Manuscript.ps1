param(
    [Parameter(Mandatory)]
    [string]$InputDir, 
    [switch]$Tag
    )
$outputDir = '.\out'
$tempDir = '\temp'
$manuscriptDir = '.\_Manuscript'
$separatorFilePath = "`".\Templates\Scene separator.md`""

If (!(Test-Path $inputDir))
{
    Write-Host "Path does not exist: $inputDir" -ForegroundColor Red
    exit
}

If (!(Test-Path $outputDir))
{
    New-Item -ItemType Directory -Path $outputDir
}

If (!(Test-Path $outputDir\$tempDir))
{
    New-Item -ItemType Directory -Path $outputDir\$tempDir
}

function New-Version {
    param(
		[Parameter()]
		[string] $InputDir
	)

    # Create structure if it doesn't exist
    $versionDir = "$InputDir\.version"
    $buildFilePath = "$versionDir\build"
    $versionSetFilePath = "$versionDir\versionset"

    if (!(Test-Path $versionDir)) {
        Write-Host "Creating version folder"
        $vd = New-Item -Path $versionDir -ItemType Directory
        $vd.Attributes = $vd.Attributes -bor [System.IO.FileAttributes]::Hidden
    }
    
    if (!(Test-Path $buildFilePath)) {
        Write-Host "Creating version file"
        $v = New-Item -Path $buildFilePath -ItemType File -Value "0"
        $v.Attributes = $v.Attributes -bor [System.IO.FileAttributes]::Hidden
        $v.Attributes = $v.Attributes -bor [System.IO.FileAttributes]::ReadOnly
    }

    if (!(Test-Path $versionSetFilePath)) {
        Write-Host "Creating version set file"
        New-Item -Path $versionSetFilePath -ItemType File -Value "1.0"
    }
    
    #Get version and increase the build number
    $versionPart = Get-Content $versionSetFilePath
    $buildNumber = [int](Get-Content $buildFilePath) + 1

    return "$versionPart.$buildNumber"    
}

$suffix = ''
if ($Tag -eq $true){
    $version = New-Version -InputDir $InputDir
    $suffix = "_$version"
}

$outputFile = (($inputDir -replace "\.\\", "") -replace "\\", "") + "$suffix.docx"

Copy-Item -Recurse -Path $inputDir\$manuscriptDir -Destination $outputDir\$tempDir -Force

$manuscriptFiles = Get-ChildItem $outputDir\$tempDir\$manuscriptDir -rec | Where-Object { $_.Name.EndsWith(".md") }
$files = New-Object Collections.Generic.List[String]

function Assert-Start-Of-Chapter {
	param(
		[Parameter()]
		[string] $filePath
	)
	
	return ((Get-Content $filePath) -join "").StartsWith("# ")
}

for ($i = 0; $i -lt $manuscriptFiles.Length; $i++)
{
    Write-Host "Processing $($manuscriptFiles[$i].FullName)..."

    if ($previousFile -ne '' `
    -and !(Assert-Start-Of-Chapter($manuscriptFiles[$i].FullName)) `
    -and !(Assert-Start-Of-Chapter($previousFile)))
    {       
         Write-Host "$($manuscriptFiles[$i].FullName) is the beginning of a new scene."
        $files.Add($separatorFilePath)
    }  

    if (Assert-Start-Of-Chapter($manuscriptFiles[$i].FullName))
    {
        Write-Host "$($manuscriptFiles[$i].FullName) is the beginning of a new chapter."
    }   

    $files.Add($manuscriptFiles[$i].FullName)
    $previousFile = $manuscriptFiles[$i].FullName;
}

& 'pandoc' $files --top-level-division=chapter --reference-doc=.\custom-reference.docx -o $outputDir\$outputFile

Remove-Item $outputDir\$tempDir\ -Recurse