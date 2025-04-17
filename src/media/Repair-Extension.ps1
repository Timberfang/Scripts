<#
.SYNOPSIS
	Fixes file extensions using czkawka.
.NOTES
	Requires czkawka to be installed, and an output file to be created using the flag '-f czkawka-output.txt'
.EXAMPLE
	.\windows_czkawka_cli.exe ext --directories .\example-dir -f czkawka-output.txt
	.\Repair-Extension.ps1

	Repairs all files that czkawka finds.
#>

$Contents = Get-Content -Path ".\czkawka-output.txt"
$OutText = $Contents | Select-String -Pattern '(".*").*(\(.*\))'
$OutText | Select-Object | ForEach-Object {
	# -replace uses regex for matching; \\\\ is two '\' characters
	$Path = $_.Matches.Groups[1] -replace '"' -replace '\\\\', '\' | Get-Item
	$ProperExtension = '.' + ($_.Matches.Groups[2].Value -replace '\(' -replace '\)')
	if (Test-Path $Path) {
		Rename-Item -Path $Path -NewName ($Path.BaseName + $ProperExtension)
	}
}
