param (
	[Parameter(Mandatory = $True)]
	[securestring]$password
)

workflow setupADForrest {
	param (
		[Parameter (Mandatory = $True, HelpMessage = "ComputerName")]
		[string]$computername,

		[Parameter (Mandatory = $True, HelpMessage = "Password for DSRM.")]
		[securestring]$password
	)

	# Rename Domain Controller
	Write-Verbose "Renaming computer..."
	Rename-Computer -NewName $computername -Force -PassThru
	Restart-Computer -Wait

	# Installing AD Domain Services
	Write-Verbose "Installing `"AD-Domain-Services`""
	Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

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

# * Confirm we have an elevated session.
If (-NOT([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
	Throw "You must run this from an elevated PowerShell session."
}

Import-Module -Name .\modules\workflow.psm1
$domConHostName = Read-Host "Hostname for Domain Controller"

# Setup AD forrest
setupADForrest -computername $domConHostName -password $password