function Test-Podman {
	<#
		.SYNOPSIS
			Test if Podman is ready for use.
	#>

	begin { Set-StrictMode -Version 3 }

	process {
		if ((Get-Command -Name 'podman' -ErrorAction SilentlyContinue) -eq '') { throw 'Podman is not installed.' }
		if ((Test-Path variable:IsLinux) -and ($IsLinux)) { return $true }
		return (& podman machine info --format json | ConvertFrom-Json).Host.MachineState -eq 'Running'
	}
}

function Start-Podman {
	<#
		.SYNOPSIS
			On non-Linux platforms, start Podman's virtual machine.
	#>

	begin { Set-StrictMode -Version 3 }

	process {
		if (!(Test-Podman) -and (!(Test-Path variable:IsLinux) -or !($IsLinux))) { & podman machine start }
	}
}

function Stop-Podman {
	<#
		.SYNOPSIS
			On non-Linux platforms, stop Podman's virtual machine.
	#>

	begin { Set-StrictMode -Version 3 }

	process {
		if ((Test-Podman) -and (!(Test-Path variable:IsLinux) -or !($IsLinux))) { & podman machine stop }
		if ((Get-Command 'wsl' -ErrorAction SilentlyContinue) -ne '' -and (wsl --list --running --quiet) -ne '') { & wsl --shutdown }
	}
}
