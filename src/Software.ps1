function Update-Software {
	<#
		.SYNOPSIS
			Update all software installed via Winget or Scoop.
	#>

	begin { Set-StrictMode -Version 3 }

	process {
		if (Test-Command 'winget') {
			Write-Verbose 'Updating software installed via Winget'
			& winget upgrade --all --include-unknown --silent
		}

		if (Test-Command 'scoop') {
			Write-Verbose 'Updating Scoop and Scoop buckets'
			& scoop update

			Write-Verbose 'Updating software installed via Scoop'
			& scoop update --all --quiet
		}
	}
}

function Test-Command {
	<#
		.SYNOPSIS
			Tests if a given command is available on the system.
	#>

	[CmdletBinding()]
	param(
		[Parameter(Mandatory)]
		[string]
		$Command
	)
	begin { Set-StrictMode -Version 3 }

	process {
		return (Get-Command -Name $Command -ErrorAction SilentlyContinue) -ne ''
	}
}

function Add-ToPath {
	<#
		.SYNOPSIS
			Add a path to the PATH environment variable.
		.DESCRIPTION
			The PATH environment variable is used to find CLI programs on the computer.
			Any programs found in the PATh can be used by typing the name (e.g. 'git')
			without writing the full/absolute path to the program.
	#>

	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[string]
		$Path
	)

	begin {
		Set-StrictMode -Version 3
		if (([System.Environment]::OSVersion.Platform -ne 'Win32NT')) {
			$UserPath = [Environment]::GetEnvironmentVariable('PATH')
		}
		else {
			$UserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
		}
	}

	process {
		if (Test-Path -Path $Path) {
			# The method is required for environment changes to be permanent
			[Environment]::SetEnvironmentVariable('Path', $UserPath + ";$Path", 'User')
			Write-Verbose -Message "Added '$Path' to user's PATH."
		}
		else {
			Write-Error -Message "'$Path' does not exist."
		}
	}
}

function Remove-FromPath {
	<#
		.SYNOPSIS
			Remove a path from the PATH environment variable.
		.DESCRIPTION
			The PATH environment variable is used to find CLI programs on the computer.
			Any programs found in the PATh can be used by typing the name (e.g. 'git')
			without writing the full/absolute path to the program.
	#>

	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[string]
		$Path
	)

	begin {
		Set-StrictMode -Version 3
		if (([System.Environment]::OSVersion.Platform -ne 'Win32NT')) {
			$UserPath = [Environment]::GetEnvironmentVariable('PATH')
		}
		else {
			$UserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
		}
	}

	process {
		if ($UserPath.Contains($Path) ) {
			# The method is required for environment changes to be permanent
			[Environment]::SetEnvironmentVariable('Path', $UserPath.Replace($Path, ''), 'User')
			Write-Verbose -Message "Removed $Path from user's PATH."
		}
	}
}
