[CmdletBinding()]
param (
	[Parameter()]
	[string]
	$Source,

	[Parameter()]
	[bool]
	$SymbolicLink = $false,

	[Parameter()]
	[bool]
	$Hide = $false
)

function Get-BooleanChoice {
	[CmdletBinding()]
	param (
		[Parameter()]
		[string]
		$Title,

		[Parameter()]
		[string]
		$Description
	)

	$YesChoice = New-Object System.Management.Automation.Host.ChoiceDescription '&Yes'
	$NoChoice = New-Object System.Management.Automation.Host.ChoiceDescription '&No'
	$ChoiceList = [System.Management.Automation.Host.ChoiceDescription[]]($YesChoice, $NoChoice)

	$Choice = $Host.UI.PromptForChoice($Title, $Description, $ChoiceList, 1)

	$Output = switch ($Choice) {
		0 { $true }
		1 { $false }
		Default { $false }
	}

	return $Output
}

# Error checks
if (-not ($PSVersionTable.PSVersion.Major -eq 5 -or $PSVersionTable.PSVersion.Major -eq 7 -and $IsWindows)) {
	Write-Error -Message 'Error: Only Windows is supported by this script.'
	Pause
	Exit
}

if ([string]::IsNullOrEmpty($Source)) {
	$Source = Read-Host -Prompt 'Please enter the path to the source folder'
	$Source = $Source -replace '"' -replace ''''
}

if (-not (Test-Path -Path $Source)) {
	Write-Error -Message 'Error: Source folder not found.'
	Pause
	Exit
}

# Use Windows API to get saved games folder - it's not in the Known Folders list, which is the preferred method for many folders.
$SavedGamePath = (New-Object -ComObject Shell.Application).NameSpace('shell:SavedGames').Self.Path

# Build directory path
[string]$FolderName = Get-Item -Path $Source | Select-Object -ExpandProperty Name
[string]$Destination = Join-Path -Path $SavedGamePath -ChildPath $FolderName

if (Test-Path -Path $Destination\*) {
	[bool]$Continue = Get-BooleanChoice -Title 'Folder not empty' -Description 'Warning: Target folder exists and is not empty. Are you sure you want to continue?'
	if (-not ($Continue)) { Exit }
}

# Create target directory & move files
New-Item -Path $Destination -ItemType Directory
Get-ChildItem -Path $Source -Recurse | Move-Item -Destination $Destination
Remove-Item -Path $Source

# Create link
if ($SymbolicLink) { [string]$Type = 'SymbolicLink' }
else { [string]$Type = 'Junction' }

New-Item -Path $Source -ItemType $Type -Value $Destination

if ($Hide) {
	$Folder = Get-Item $Source
	$Folder.Attributes += "Hidden"
}
