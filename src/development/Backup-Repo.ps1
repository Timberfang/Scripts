function Backup-Repo {
	[CmdletBinding()]
	param (
		[Parameter()]
		[string]
		$URL
	)
	$Path = Join-Path $PWD ($URL -replace '.git' | Split-Path -Leaf)
	& git clone --mirror $URL $Path
	& git -C $Path lfs fetch --all
}
