function Remove-EmptyDirectory {
	<#
		.SYNOPSIS
			Recursively remove empty directories.
		.DESCRIPTION
			Search through a directory structure, removing all empty subdirectories.
			If the parent directory is empty after processing all subdirectories,
			it will be removed.

			Any directory that contains at least one file will be skipped.
		.PARAMETER Path
			The path to the directory to process.
		.EXAMPLE
			Remove-EmptyDirectory -Path 'C:\MyDirectory'

			Removes all empty directories within 'C:\MyDirectory'.
		.NOTES
			To recursively remove non-empty directories, use the Remove-Item cmdlet
			with the -Recurse parameter.
	#>
	[CmdletBinding(SupportsShouldProcess)]
	param(
		[Parameter(Mandatory, ValueFromPipeline)]
		[string]
		$Path
	)

	begin { Set-StrictMode -Version 3 }

	process {
		($PSCmdlet.ShouldProcess('podman', 'Start podman machine'))
		foreach ($Child in Get-ChildItem $Path -Force -Directory) {
			Write-Verbose "Scanning child directory '$Child'"
			if ($PSCmdlet.ShouldProcess($Child)) { Remove-Directory $Child.FullName }
		}
		$Contents = Get-ChildItem $Path -Force
		if ($null -eq $Contents) {
			if ($PSCmdlet.ShouldProcess($Child, 'Remove-Item')) { Remove-Item $Path -Force }
		}
	}
}

function Find-File {
	<#
		.SYNOPSIS
			Find a file in the specified directory and all of its subdirectories.
		.PARAMETER Pattern
			The pattern to search for.
		.PARAMETER Path
			The directory to search in. The default is the current directory.
		.EXAMPLE
			Find-File -Pattern 'myFile.txt' -Path 'C:\MyDirectory'

			Finds the file 'myFile.txt' in the 'C:\MyDirectory' directory and its subdirectories.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[string]
		$Pattern,

		[Parameter()]
		[string]
		$Path = $PWD
	)

	begin { Set-StrictMode -Version 3 }

	process {
		Write-Verbose "Searching for '$Pattern' in directory '$Path'"
		$Result = Get-ChildItem $Path -Recurse -Filter $Pattern -ErrorAction SilentlyContinue

		Write-Verbose 'Outputting results to table'
		$Result | Format-Table -AutoSize
	}
}

function New-File {
	<#
		.SYNOPSIS
			Create a new file with the specified name and extension.
		.PARAMETER Name
			The name of the file.
		.PARAMETER Path
			The path to the directory where the file should be created.

			Defaults to the current directory.
		.EXAMPLE
			New-File -Path 'C:\MyDirectory' -Name 'myFile.log'

			Creates a new file named 'myFile.log' in the 'C:\MyDirectory' directory.
	#>
	[CmdletBinding(SupportsShouldProcess)]
	param (
		[Parameter(Mandatory)]
		[string]
		$Name,

		[Parameter()]
		[string]
		$Path = $PWD
	)

	begin { Set-StrictMode -Version 3 }

	process {
		if (-not (Test-Path $Path)) {
			if ($PSCmdlet.ShouldProcess($Path, 'New-Item')) { New-Item $Path -ItemType Directory }
		}
		if ($PSCmdlet.ShouldProcess($Path, 'New-Item')) { New-Item $Path -ItemType File -Name $Name | Out-Null }
	}
}

function New-Directory {
	<#
		.SYNOPSIS
			Create a new directory with the specified name.
		.PARAMETER Name
			The name of the directory.
		.PARAMETER Path
			The path to the directory where the new directory should be created.

			Defaults to the current directory.
		.EXAMPLE
			New-Directory -Path 'C:\MyDirectory' -Name 'myFile.log' -Extension '.log'

			Creates a new directory named 'newFolder' in the 'C:\MyDirectory' directory.
	#>
	[CmdletBinding(SupportsShouldProcess)]
	param (
		[Parameter(Mandatory)]
		[string]
		$Name,

		[Parameter()]
		[string]
		$Path = $PWD
	)

	begin { Set-StrictMode -Version 3 }

	process {
		if ($PSCmdlet.ShouldProcess($Path, 'New-Item')) { New-Item $Path -ItemType Directory -Name $Name | Out-Null }
	}
}

function New-Link {
	<#
		.SYNOPSIS
			Create a new directory junction.
		.DESCRIPTION
			Creates a new directory junction pointing to a specified destination.
			If the path already exists, it will be moved to the destination first.
		.PARAMETER Path
			The path to the junction point. This is where the junction will be created.
		.PARAMETER Destination
			The path the junction points to. This is the target directory.
		.PARAMETER Hidden
			Hides the junction.
		.EXAMPLE
			New-Link -Path 'C:\MyJunction' -Destination 'C:\MyDirectory'
			Creates a new junction at 'C:\MyJunction' that points to 'C:\MyDirectory'.
	#>
	[CmdletBinding(SupportsShouldProcess)]
	param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[string]
		$Path,

		[Parameter(Mandatory)]
		[string]
		$Destination,

		[Parameter()]
		[switch]
		$Hidden
	)

	begin {
		Set-StrictMode -Version 3
		if ([System.Environment]::OSVersion.Platform -ne 'Win32NT') { throw 'Windows is required to run this script.' }
	}

	process {
		# see https://stackoverflow.com/questions/3038337/powershell-resolve-path-that-might-not-exist
		$Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
		$Destination = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Destination)

		if (Test-Path -Path $Path) {
			if ($PSCmdlet.ShouldProcess($Path, "Move-Item -Destination $Destination")) { Move-Item -Path $Path -Destination $Destination }
		}
		if (!(Test-Path -Path $Destination)) { throw "'$Destination' not found" }
		if ($PSCmdlet.ShouldProcess($Path, "New-Item")) { New-Item -Path $Path -Value $Destination -ItemType Junction }
		if ($Hidden) {
			if ($PSCmdlet.ShouldProcess($Path, "Hide")) {
				$Folder = Get-Item -Path $Path
				$Folder.Attributes += 'Hidden'
			}
		}
	}
}

function Remove-Duplicates {
	<#
		.SYNOPSIS
			Remove duplicate lines from a plain text file.
		.PARAMETER Path
			Path to the input file.
		.PARAMETER Destination
			Path to the output file.
	#>

	[CmdletBinding()]
	param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[string]
		$Path,

		[Parameter(Mandatory)]
		[string]
		$Destination
	)

	begin { Set-StrictMode -Version 3 }

	process {
		if (-not (Test-Path -Path $Path)) { throw "Path at '$Path' not found" }
		Get-Content -Path $Path | Sort-Object -Unique | Set-Content -Path $Destination
	}
}
