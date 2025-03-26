
$inputDir = "..\backdrops"
$outputDir = "..\backdrops"

if (!(Test-Path $outputDir))
{
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

foreach ($file in Get-ChildItem -Path $inputDir -File)
{
    $inputFile = $file.FullName
    $baseName = $file.BaseName
    $outputFile = Join-Path $outputDir ("{0}.acrylic.jpg" -f $baseName)
    
    if (Test-Path $outputFile)
    {
        Write-Host "Skipping $($file.Name): $outputFile already exists."
        continue
    }
    
    ffmpeg -i $inputFile -vf "gblur=sigma=40:steps=6,drawbox=x=0:y=0:w=iw:h=ih:color=#1f1f28@0.6:t=fill,eq=brightness=0.03:contrast=1.05:saturation=0.8,deband=range=16:direction=-PI:1thr=0.05:2thr=0.05:3thr=0.05,noise=alls=2:allf=u" -q:0 1 $outputFile
}
