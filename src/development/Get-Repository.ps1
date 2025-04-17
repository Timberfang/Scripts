#Requires -Version 5.1
#Requires -Modules PowerShellForGitHub
Set-StrictMode -Version 3.0
function Read-Choice {
	$Selection = $RepoList | Out-GridView -PassThru -Title 'Select one or more repositories'
	if (-Not $Selection){Exit}
	ForEach($Entry in $Selection) {
		Get-Repository -OwnerName $Entry.Owner -RepositoryName $Entry.Repo
	}
}

function Get-Repository {
	<#
		.SYNOPSIS
			Download a GitHub repository.

		.DESCRIPTION
			This function will download a GitHub repository.
			This repository can be either public or private.

		.PARAMETER OwnerName
			Name of owner of repository. For example, for the repository PowerShell/vscode-powershell, the owner is "PowerShell".

		.PARAMETER RepositoryName
			Name of repository. For example, for the repository PowerShell/vscode-powershell, the repository is "vscode-powershell".

		.EXAMPLE
			Get-Repo -Owner Lycaon37 -Repo PZ-Improved-Komodo

			Download the repository PZ-Improved-Komodo

		.EXAMPLE
			Get-Repo -Owner ciderapp -Repo cider-releases -Asset 6

			Download the repository for Cider."
		#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)]
		[string]$OwnerName,

		[Parameter(Mandatory,ValueFromPipeline)]
		[string]$RepositoryName,

		[int]$Asset = 0
	)
	begin {
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
		git clone https://github.com/$OwnerName/$RepositoryName.git $PSScriptRoot\$RepositoryName
	}
	end {
		Write-Verbose "Download of $RepositoryName complete."
	}
}

# Collect data from CSV
$RepoList = Get-ChildItem -Path $PSScriptRoot -Filter *.csv | ForEach-Object {
	Import-CSV -Path $_
}

Read-Choice
