param (
        [Parameter(Mandatory)]
        [string]$referenceDocPath, 
        [Collections.Generic.List[String]]$files, 
        [string]$outputFilePath
    )

& 'pandoc' $files --top-level-division=chapter --reference-doc=$referenceDocPath -o $outputFilePath