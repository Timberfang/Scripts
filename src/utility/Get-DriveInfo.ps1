Set-StrictMode -Version 3.0
#Requires -Version 5.1

# Get used space on a drive, then warn if storage usage exceeds 65%.

function Get-DriveInfo {
	[CmdletBinding()]
	param(
		$InformationPreference= "Continue",
		[int]$WarnPercent = '75'
	)
	Get-PSDrive -PSProvider FileSystem | ForEach-Object {
		if (($_.Used / ($_.Free + $_.Used)).ToString("P") -ge $WarnPercent) {
			[PSCustomObject]@{
				Name = $_.Name
				"Used (GB)" = $_.Used
				"Free (GB)" = $_.Free
				"Total (GB)" = ($_.Used + $_.Free)
				"Used (%)" = (($_.Used / ($_.Free + $_.Used)).ToString("P") + ' - Warning!')
				Provider = $_.Provider
				Root = $_.Root
			}
		}
		else {
			[PSCustomObject]@{
				Name = $_.Name
				"Used (GB)" = $_.Used
				"Free (GB)" = $_.Free
				"Total (GB)" = ($_.Used + $_.Free)
				"Used (%)" = ($_.Used / ($_.Free + $_.Used)).ToString("P")
				Provider = $_.Provider
				Root = $_.Root
			}
		}
	}
}
