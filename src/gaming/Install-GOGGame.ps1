#Requires -Version 5.1

[CmdletBinding()]
param (
	[Parameter(Mandatory)]
	[string]
	$Path
)

begin {
	Set-StrictMode -Version 3
	if ([System.Environment]::OSVersion.Platform -ne 'Win32NT') { throw 'This script only functions on Windows.' }
	if (!(Test-Path -Path $Path -PathType Container)) { throw "Path '$Path' is not a valid GOG installation directory. Ensure that it is a directory containing one or more installation executables." }
	Set-Variable Signers -Option Constant -Value @('GOG  sp. z o.o', 'GOG Sp. z o.o.', 'GOG Limited') # Update this if any new signer names are discovered

	$DLCPath = Join-Path $Path 'dlc'
	$UpdatePath = Join-Path $Path 'patches'
	$DLCPresent = Test-Path -Path $DLCPath
	$UpdatePresent = Test-Path -Path $UpdatePath
}

process {
	[System.IO.FileInfo[]] $Files = Get-ChildItem -Path $Path -File -Filter *.exe
	if ($UpdatePresent) { $Files += Get-ChildItem -Path $UpdatePath -File -Filter *.exe }
	if ($DLCPresent) { $Files += Get-ChildItem -Path $DLCPath -File -Filter *.exe }

	foreach ($File in $Files) {
		# Test if executable has a *valid* digital signature from GOG
		$FilePath = $File.FullName
		$Signature = Get-AuthenticodeSignature $FilePath
		$Signer = (($Signature.SignerCertificate.Subject) -split ', ')[0].Replace('CN=', '').Trim()
		if ($Signature.Status -ne 'Valid') { throw "Invalid signature for executable at '$FilePath'; this executable may have been tampered with." }
		if ($Signer -notin $Signers) { throw "Executable at '$FilePath' was not signed by GOG; this executable may have been tampered with." }

		Start-Process $FilePath -Wait
	}
}
