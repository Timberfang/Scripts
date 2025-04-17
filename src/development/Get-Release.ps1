#Requires -Version 5.1
#Requires -Modules PowerShellForGitHub,PSMenu
Set-StrictMode -Version 3.0
$InformationPreference = 'Continue'

function Get-PrivateRelease {
	<#
		.SYNOPSIS
			Download a release from a GitHub repository.

		.DESCRIPTION
			This function will download a release artifact from a GitHub repository using a Personal Access Token (PAT)
			This repository can be either public or private.

		.PARAMETER OwnerName
			Name of owner of repository. For example, for the repository PowerShell/vscode-powershell, the owner is "PowerShell".

		.PARAMETER RepositoryName
			Name of repository. For example, for the repository PowerShell/vscode-powershell, the repository is "vscode-powershell".

		.PARAMETER Asset
			Use if there is more than one asset in the release, such as if a release has separate Windows and MacOS releases.
			By default, Get-PrivateRelease will download the highest release in the list. This parameter is a number of assets to skip.
			For example, to get the seventh asset from the top, use -Asset 6.

		.PARAMETER DestinationPath
			The path that the downloaded files will be saved to. If the given path does not exist, it will be created automatically.
			By default, this path is a folder called "Release Assets" within the folder running the script.

		.PARAMETER SkipExisting
			If this is true, the script will skip over files for downloading if they already exist in the target folder.
			This is set to true by default. Set to false to overwrite existing files.

		.EXAMPLE
			Get-PrivateRelease -Owner Lycaon37 -Repo PZ-Improved-Komodo

			Download PZ-Improved-Komodo.zip

		.EXAMPLE
			Get-PrivateRelease -Owner ciderapp -Repo cider-releases -Asset 6

			Download the .snap release of Cider."
	#>

	[CmdletBinding()]
	param(
		[Parameter(Mandatory)]
		[string]$OwnerName,

		[Parameter(Mandatory,ValueFromPipeline)]
		[string]
		$RepositoryName,

		[Parameter()]
		[int]
		$Asset = 0,

		[Parameter()]
		[string]
		$DestinationPath = (Join-Path $PSScriptRoot 'Release Assets'),

		[Parameter()]
		[bool]
		$SkipExisting = $true
	)

	begin {
		# Create the destination path, if it doesn't exist yet
		if (-not(Test-Path $DestinationPath)) { New-Item $DestinationPath -ItemType Directory | Out-Null }

		# Test GitHub Authentication.
		if(-not (Test-GitHubAuthenticationConfigured)){
			$SecureString = (Read-Host "Please enter your personal access token." | ConvertTo-SecureString -AsPlainText -Force)
			$Credential = New-Object System.Management.Automation.PSCredential "username is ignored", $SecureString
			Set-GitHubAuthentication -Credential $Credential
			$SecureString = $null # clear this out now that it's no longer needed
			$Credential = $null # clear this out now that it's no longer needed
		}
	}

	process {
		# Find release asset.
		Write-Information "Finding Release..."
		$ReleaseAsset = Get-GitHubRelease -OwnerName $OwnerName -RepositoryName $RepositoryName -Latest |
		Get-GitHubReleaseAsset |
		Select-Object -First 1 -Skip $Asset
		$AssetName = $ReleaseAsset.Name

		if ((Test-Path $DestinationPath\$AssetName) -and ($SkipExisting -eq $true)) {
			Write-Information "$AssetName exists, skipping..."
		}
		else {
			Write-Information "Downloading $AssetName from $OwnerName..."
			$ReleaseAsset | Get-GitHubReleaseAsset -Path $DestinationPath\$AssetName -Force | Write-Output
		}
	}

	end {
		Write-Information "Download of $AssetName complete."
	}
}

function Get-PublicRelease {
	<#
		.SYNOPSIS
			Download a release from a GitHub repository.

		.DESCRIPTION
			This function will download a release artifact from a GitHub repository.
			This repository CANNOT be private. For private repositories, please see Get-PrivateRelease.

		.PARAMETER OwnerName
			Name of owner of repository. For example, for the repository PowerShell/vscode-powershell, the owner is "PowerShell".

		.PARAMETER RepositoryName
			Name of repository. For example, for the repository PowerShell/vscode-powershell, the repository is "vscode-powershell".

		.PARAMETER Asset
			Use if there is more than one asset in the release, such as if a release has separate Windows and MacOS releases.
			By default, Get-PublicRelease will download the highest release in the list. This parameter is a number of assets to skip.
			For example, to get the seventh asset from the top, use -Asset 6.

		.PARAMETER DestinationPath
			The path that the downloaded files will be saved to. If the given path does not exist, it will be created automatically.
			By default, this path is a folder called "Release Assets" within the folder running the script.

		.PARAMETER SkipExisting
			If this is true, the script will skip over files for downloading if they already exist in the target folder.
			This is set to true by default. Set to false to overwrite existing files.

		.EXAMPLE
			Get-PublicRelease -Owner Lycaon37 -Repo PZ-Improved-Komodo
			Download PZ-Improved-Komodo.zip

		.EXAMPLE
			Get-PublicRelease -Owner ciderapp -Repo cider-releases -Asset 6
			Download the .snap release of Cider."
	#>

	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[string]
		$OwnerName,

		[Parameter(Mandatory,ValueFromPipeline)]
		[string]
		$RepositoryName,

		[Parameter()]
		[int]
		$Asset = 0,

		[Parameter()]
		[string]
		$DestinationPath = (Join-Path $PSScriptRoot 'Release Assets'),

		[Parameter()]
		[bool]
		$SkipExisting = $true
	)

	begin {
		# Create the destination path, if it doesn't exist yet
		if (-not(Test-Path $DestinationPath)) { New-Item $DestinationPath -ItemType Directory | Out-Null }
	}

	process {
		# Find the relevant release asset
		Write-Information "Finding Release..."
		$RepositoryInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/$OwnerName/$RepositoryName/releases"
		$Version = $RepositoryInfo[0].tag_name
		$ReleaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/$OwnerName/$RepositoryName/releases/tags/$Version"

		# Find the download link for the release asset and download the asset
		$AssetUrl = $ReleaseInfo.assets[$Asset].browser_download_url
		$AssetName = $ReleaseInfo.assets[$Asset].name

		if ((Test-Path $DestinationPath\$AssetName) -and ($SkipExisting -eq $true)) {
			Write-Information "$AssetName exists, skipping..."
		}
		else {
			Write-Information "Downloading $AssetName from $OwnerName..."
			Start-BitsTransfer -Source $AssetUrl -Destination $DestinationPath\$AssetName
		}
	}

	end {
		Write-Information "Download of $AssetName complete."
	}
}

function Get-HTTPRelease {
	<#
		.SYNOPSIS
			Download a file from a website through Regular Expression (regex) filtering.

		.DESCRIPTION
			This function will download a file from a website using regular expressions. It was intended to find software releases, but it can be used with any file if desired.
			Given a certain base URL and a regular expression, it will dynamically find a specific file.
			This only functions with websites that define links statically via http, and not dynamically with javascript.

		.PARAMETER URL
			The URL link to the website where the file is hosted.

		.PARAMETER Pattern
			The regular expression pattern to search for the file.

		.PARAMETER Asset
			Use if there is more than one fie matching the regular expression. The script will skip the number results found by the asset parameter.
			By default, Get-HTTPRelease will download the highest release in the list. This parameter is a number of assets to skip.
			For example, to get the seventh asset from the top, use -Asset 6.

		.PARAMETER DestinationPath
			The path that the downloaded files will be saved to. If the given path does not exist, it will be created automatically.
			By default, this path is a folder called "Release Assets" within the folder running the script.

		.PARAMETER SkipExisting
			If this is true, the script will skip over files for downloading if they already exist in the target folder.
			This is set to true by default. Set to false to overwrite existing files.

		.EXAMPLE
			Get-PublicRelease -URL https://dolphin-emu.org/download/ -Pattern *dolphin-master-5.0-*-x64.7z
			Download the latest beta Dolphin Emulator release for Windows.
	#>

	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[String]
		$URL,

		[Parameter(Mandatory)]
		[String]
		$Pattern,

		[Parameter()]
		[int]
		$Asset = 0,

		[Parameter()]
		[String]
		$DestinationPath = (Join-Path $PSScriptRoot 'Release Assets'),

		[Parameter()]
		[bool]
		$SkipExisting = $true
	)

	begin {
		# Create the destination path, if it doesn't exist yet
		if (-not(Test-Path $DestinationPath)) { New-Item $DestinationPath -ItemType Directory | Out-Null }
	}

	process {
		# Find the latest version of the file
		$Website = Invoke-WebRequest -Uri $URL
		$AssetURl = $Website.links.href | Where-Object {$_ -Like $Pattern} | Select-Object -First 1 -Skip $Asset
		$AssetName = $AssetURL | Split-Path -Leaf

		if ((Test-Path $DestinationPath\$AssetName) -and ($SkipExisting -eq $true)) {
			Write-Information "$AssetName exists, skipping..."
		}
		else {
			Write-Information "Downloading $AssetName from $AssetURL..."
			Start-BitsTransfer -Source $AssetURl -Destination $DestinationPath\$AssetName
		}
	}

	end {
		Write-Information "Download of $AssetName complete."
	}
}

# Collect data from CSV
$ReleaseList = Get-ChildItem -Path $PSScriptRoot -Filter *.csv | ForEach-Object {
	Import-CSV -Path $_
}

# Get the names from the object array
$NameList = $ReleaseList | Select-Object -ExpandProperty name

# Prompt the user to select an option
$SelectedNames = Show-Menu $NameList -MultiSelect

# Find the matching object based on the selected name
$Selection = $ReleaseList | Where-Object { $SelectedNames -contains $_.name }

# Check if a matching object was found
if ($Selection) {
	# Object found, do something with it
	ForEach($Entry in $Selection) {
		# All GitHub releases require the "Repo" property. HTTP releases don't have the this property, so it can be used to find the type.
		# This reduces the amount of required fields in the database, simplifying the system.
		if ($Entry | Get-Member -Name 'Repo' -MemberType NoteProperty) {
			if ($Entry.Private -eq $true) {
				Get-PrivateRelease -OwnerName $Entry.Owner -RepositoryName $Entry.Repo -Asset $Entry.Asset
			}
			else {
				Get-PublicRelease -OwnerName $Entry.Owner -RepositoryName $Entry.Repo -Asset $Entry.Asset
			}
		}
		else {
			Get-HTTPRelease -URL $Entry.URL -Pattern $Entry.Pattern -Asset $Entry.Asset
		}
	}
}
