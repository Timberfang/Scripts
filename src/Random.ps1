function Get-RandomString {
	<#
		.SYNOPSIS
			Generate a random string of ASCII characters.
		.PARAMETER Length
			Number of characters to output.
		.PARAMETER CharSet
			The characters to use in generation: Numbers (0-9), Lowercase (a-z), Uppercase (A-Z), and Symbols (everything else).
	#>

	[CmdletBinding()]
	param (
		[ValidateRange(1, [int]::MaxValue)]
		[Parameter(ValueFromPipeline)]
		[int]
		$Length = 12,

		[ValidateSet('Numbers', 'Lowercase', 'Uppercase', 'Symbols')]
		[Parameter()]
		[string[]]
		$CharSet = @('Numbers', 'Lowercase', 'Uppercase')
	)

	begin {
		Set-StrictMode -Version 3
		$CharSets = @{
			Numbers   = 48..57
			Lowercase = 97..122
			Uppercase = 65..90
			Symbols   = 58..64 + 91..96 + 123..126
		}
		$Chars = $CharSet | ForEach-Object { $CharSets.$_ }
	}

	process { return (($Chars * 80 | Get-Random -Count $Length | ForEach-Object	{ [char]$_ }) -join "") }
}

function Get-RandomNumber {
	<#
		.SYNOPSIS
			Generate a random integer.
		.PARAMETER Length
			Number of digits to output.
		.NOTES
			These numbers are pseudorandom, but are NOT cryptographically secure.
			Do not use this function for security purposes.
	#>

	[CmdletBinding()]
	param (
		[ValidateRange(1, [int]::MaxValue)]
		[Parameter(ValueFromPipeline)]
		[int]
		$Length = 4
	)

	begin {
		Set-StrictMode -Version 3
		[int]$Min = [Math]::Pow(10, $Length - 1)
		[int]$Max = [Math]::Pow(10, $Length) - 1
	}

	process {
		return Get-Random -Minimum $Min -Maximum $Max
	}
}
