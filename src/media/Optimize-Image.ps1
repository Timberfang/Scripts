[CmdletBinding()]
param (
	[Parameter(Mandatory)]
	[System.IO.DirectoryInfo]
	$Path
)
Set-StrictMode -Version 3

# TODO: Support both files and folders
# TODO: Support recursion through a directory
# TODO: Add comment-based help

# Dependencies check
if (-not (Get-Command "magick" -ErrorAction SilentlyContinue)) {
	throw 'ImageMagick not found on PATH'
}
if (-not (Get-Command "caesiumclt" -ErrorAction SilentlyContinue)) {
	throw 'Caesiumclt not found on PATH'
}

# Get files - if transparent, must keep as a png, as jpeg doesn't support transparency. Jpeg is smaller, so preferred when possible.
[System.IO.FileInfo[]]$ImageFiles = Get-ChildItem -Path $Path -File | Where-Object Extension -In ('.jpeg', '.jpg', '.jfif', '.png')
[string[]]$ImageTransparency = & magick identify -format '%[opaque]\n' $ImageFiles # Slow step, but no other cross-platform methods that I'm aware of

# Consolidate data from above
[PSCustomObject[]]$Images = @()
for ($i = 0; $i -le $ImageFiles.Count - 1; $i++) {
	[PSCustomObject]$ImageData = @{
		File   = $ImageFiles[$i]
		Opaque = $ImageTransparency[$i]
	}
	$Images += $ImageData
}

# Prepare data - bit of a hack, caesium only accepts folders for bulk processing, not lists of files
# Transparent
$TransparentPath = Join-Path -Path $Path -ChildPath 'png'
if (-not (Test-Path $TransparentPath)) { New-Item -Path $TransparentPath -ItemType Directory | Out-Null }
$Images | Where-Object Opaque -EQ 'False' | Select-Object -Property File | Move-Item -Destination $TransparentPath

# Opaque (non-transparent)
$OpaquePath = Join-Path -Path $Path -ChildPath 'jpg'
if (-not (Test-Path $OpaquePath)) { New-Item -Path $OpaquePath -ItemType Directory | Out-Null }
$Images | Where-Object Opaque -EQ 'True' | Select-Object -Property File | Move-Item -Destination $OpaquePath

# Compress images - quality 0 will attempt to optimize image. Nearly maximized lossless compression for png, quality 80 mozjpeg compression for jpeg.
& Caesiumclt --output $TransparentPath --quality 0 --exif -RS $TransparentPath
& Caesiumclt --output $OpaquePath --output-format jpg --quality 0 --exif -RS $OpaquePath
Get-ChildItem -Path $OpaquePath -File -Exclude *.jpg | Rename-Item -NewName { $_.BaseName + '.jpg' } # Another hack; Caesium doesn't change extensions when changing encoding

# Cleanup
Get-ChildItem -Path $TransparentPath | Move-Item -Destination $Path
Get-ChildItem -Path $OpaquePath | Move-Item -Destination $Path
Remove-Item $TransparentPath
Remove-Item $OpaquePath
