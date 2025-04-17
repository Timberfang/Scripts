function Add-ToPath {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[string]
		$Path
	)

	begin {
		$UserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
	}

	process {
		if ( $UserPath.Contains($Path) ) {
			Write-Error -Message "Error: $Path already exists in user's PATH."
		}

		elseif (Test-Path -Path $Path) {
			# The method is required for environment changes to be permanent
			[Environment]::SetEnvironmentVariable('Path', $UserPath + ";$Path", 'User')
			Write-Verbose -Message "Added $Path to user's PATH."
		}

		else {
			Write-Error -Message "Error: $Path does not exist."
		}
	}
}
