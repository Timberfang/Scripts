function Remove-FromPath {
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
		if ( -not $UserPath.Contains($Path) ) {
			Write-Error -Message "Error: $Path does not exist in user's PATH."
		}

		else {
			# The method is required for environment changes to be permanent
			[Environment]::SetEnvironmentVariable('Path', $UserPath.Replace($Path, ''), 'User')
			Write-Verbose -Message "Removed $Path from user's PATH."
		}
	}
}
