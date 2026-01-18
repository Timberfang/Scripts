function Clear-SavedHistory {
	<#
		.SYNOPSIS
			Clear all command history.
		.NOTES
			Inspired by the work of mkelement0 at Stack Overflow:
			https://stackoverflow.com/questions/13257775/powershells-clear-history-doesnt-clear-history/38807689#38807689

			See this GitHub issue for information on the possibility of an official command for this:
			https://github.com/PowerShell/PowerShell/issues/25933
	#>

	[CmdletBinding(SupportsShouldProcess)]
	param(
	)

	begin {
		Set-StrictMode -Version 3
		$HistoryFile = (Get-PSReadlineOption).HistorySavePath
	}

	process {
		if (-not $PSCmdlet.ShouldProcess("Entire command history from all sessions")) { return }

		Clear-Host
		Clear-History
		if (Test-Path -Path $HistoryFile -PathType Leaf) {
			Remove-Item -Path $HistoryFile
			New-Item -Path $HistoryFile -ItemType File | Out-Null
		}
		[Microsoft.PowerShell.PSConsoleReadLine]::ClearHistory()
	}
}
