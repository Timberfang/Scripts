[CmdletBinding()]
param (
	# Password length
	[Parameter()]
	[int]
	$Length = 12,

	# Character set to use in the password. Defaults to capital and lowercase letters, numbers, and symbols
	[Parameter()]
	[char[]]
	$CharSet = @([char]33..[char]126)
)

$CharSet | Get-Random -Count $Length | Join-String
