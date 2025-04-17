Set-StrictMode -Version 3.0
#Requires -Version 7.0

# Find missing numbers in a list of file names containing four digit numbers in parentheses.
# Outputs list of missing numbers to pipeline.
[System.Int32[]]$Iteration = Get-ChildItem $Path | Where-Object{$_.Name -match "\(\d{4}\)"} | ForEach-Object{$Matches[0]}
$Iteration[0]..$Iteration[-1] | Where-Object{$_ -notin $Iteration}
