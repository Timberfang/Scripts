function Convert-ToMeters {
	<#
		.SYNOPSIS
			Convert U.S. customary units of length to meters.
		.PARAMETER Inches
			Number of inches, computed at 0.0254 meters per inch.
		.PARAMETER Feet
			Number of feet, computed at 0.3048 meters per foot.
		.PARAMETER Yards
			Number of yards, computed as 0.9144 meters per yard.
		.PARAMETER Miles
			Number of miles, computed at 1609.344 meters per mile.
	#>

	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline)]
		[float]
		$Inches,

		[Parameter()]
		[float]
		$Feet,

		[Parameter()]
		[float]
		$Yards,

		[Parameter()]
		[float]
		$Miles
	)

	begin { Set-StrictMode -Version 3 }

	process {
		$Meters = 0
		if (Test-Path variable:Inches) { $Meters += $Inches * 0.0254 }
		if (Test-Path variable:Feet) { $Meters += $Feet * 0.3048 }
		if (Test-Path variable:Yards) { $Meters += $Yards * 0.9144 }
		if (Test-Path variable:Miles) { $Meters += $Miles * 1609.344 }
		return $Meters
	}
}

function Convert-ToKilograms {
	<#
		.SYNOPSIS
			Convert U.S. customary units of mass to kilograms.
		.PARAMETER Ounces
			Number of ounces, computed at 0.028349523125 kilograms per ounce.
		.PARAMETER Pounds
			Number of feet, computed at 0.45359237 kilograms per pound.
		.PARAMETER Tons
			Number of yards, computed as 907.18474 kilograms per ton.
	#>

	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline)]
		[float]
		$Ounces,

		[Parameter()]
		[float]
		$Pounds,

		[Parameter()]
		[float]
		$Tons
	)

	begin { Set-StrictMode -Version 3 }

	process {
		$Kilograms = 0
		if (Test-Path variable:Ounces) { $Kilograms += $Ounces * 0.028349523125 }
		if (Test-Path variable:Pounds) { $Kilograms += $Pounds * 0.45359237 }
		if (Test-Path variable:Tons) { $Kilograms += $Tons * 907.18474 }
		return $Kilograms
	}
}
