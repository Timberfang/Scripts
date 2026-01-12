
function Get-GitHubRelease {
	<#
		.SYNOPSIS
			Get information on the latest release of a GitHub repository.
		.PARAMETER Owner
			The user or organization who owns the repository.
		.PARAMETER Name
			The name of the repository.
		.NOTES
			This function uses GitHub's REST API. According to GitHub's policy,
			unauthenticated requests - like the ones used in this function -
			have a limit of sixty requests per hour. Each use of this function
			counts as one request. If this limit is exceeded, further requests
			may be temporarily blocked.
		.EXAMPLE
			Get-GitHubRelease -Owner PowerShell -Name PSScriptAnalyzer

			Get information on the latest release of PSScriptAnalyzer at the URL
			https://github.com/PowerShell/PSScriptAnalyzers
	#>

	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[string]
		$Owner,

		[Parameter(Mandatory)]
		[string]
		$Name
	)
	begin { Set-StrictMode -Version 3 }

	process { return Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Name/releases/latest" }
}

function Get-GitHubReleaseAsset {
	<#
		.SYNOPSIS
			Get information on the latest release assets of a GitHub repository.
		.PARAMETER Owner
			The user or organization who owns the repository.
		.PARAMETER Name
			The name of the repository.
		.PARAMETER Pattern
			Find a specific asset by name. Wildcards using '*' are supported.
			By default, it will select the first release asset.
		.NOTES
			This function uses GitHub's REST API. According to GitHub's policy,
			unauthenticated requests - like the ones used in this function -
			have a limit of sixty requests per hour. Each use of this function
			counts as one request. If this limit is exceeded, further requests
			may be temporarily blocked.
		.EXAMPLE
			Get-GitHubReleaseAsset -Owner PowerShell -Name PSScriptAnalyzer

			Get information on the latest release asset of PSScriptAnalyzer at the
			URL https://github.com/PowerShell/PSScriptAnalyzers
		.EXAMPLE
			$Asset = Get-GitHubReleaseAsset -Owner microsoft -Name terminal -Pattern Microsoft.WindowsTerminal_*_x64.zip
			Invoke-WebRequest -Uri $Asset.browser_download_url -OutFile $Asset.name

			Download the 64-bit version of the Windows Terminal.
	#>

	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[string]
		$Owner,

		[Parameter(Mandatory)]
		[string]
		$Name,

		[Parameter()]
		[string]
		$Pattern = '*'
	)

	begin { Set-StrictMode -Version 3 }

	process {
		$ReleaseInfo = Get-GitHubRelease -Owner $Owner -Name $Name
		return $ReleaseInfo.assets | Where-Object name -Like $Pattern | Select-Object -First 1
	}
}
