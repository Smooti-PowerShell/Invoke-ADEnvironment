param (
	[Parameter(Mandatory = $True)]
	[string]$newHostName,

	[Parameter(Mandatory = $True)]
	[securestring]$password
)

# * Confirm we have an elevated session.
If (-NOT([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
	Throw "You must run this from an elevated PowerShell session."
}

Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Import-Module -Name .\modules\master.psm1

workflow Build-ADForrest {
	param (
		[Parameter (Mandatory = $True, HelpMessage = "ComputerName")]
		[string]$newHostName,

		[Parameter (Mandatory = $True, HelpMessage = "Password for DSRM.")]
		[securestring]$password
	)

	# Rename Domain Controller
	Write-Verbose "Renaming computer..."
	Rename-Computer -NewName $newHostName -Force -PassThru
	Restart-Computer -Wait

	# Installing AD Domain Services
	Write-Verbose "Installing `"AD-Domain-Services`""

	# AD Forrest parameters
	$params = @{
		CreateDnsDelegation           = $false
		DatabasePath                  = 'C:\Windows\NTDS'
		DomainMode                    = 'WinThreshold'
		DomainName                    = 'testbed.local'
		ForestMode                    = 'WinThreshold'
		InstallDns                    = $true
		LogPath                       = 'C:\Windows\NTDS'
		NoRebootOnCompletion          = $true
		SafeModeAdministratorPassword = $password
		SysvolPath                    = 'C:\Windows\SYSVOL'
		Force                         = $true
	}

	# Create Forrest
	Install-ADDSForest @params
	Restart-Computer -Wait

	New-ADTestUsers

}

# Setup AD forrest
Build-ADForrest $NewHostName $password