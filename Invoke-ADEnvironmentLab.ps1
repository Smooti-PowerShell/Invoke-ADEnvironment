param (
	[Parameter (Mandatory = $False, HelpMessage = "ComputerName or IP address.")]
	[string]$computername = $env:ComputerName,

	[Parameter(Mandatory = $True)]
	[securestring]$password
)

# * Confirm we have an elevated session.
If (-NOT([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
	Throw "You must run this from an elevated PowerShell session."
}

Import-Module -Name .\modules\workflow.psm1

# Setup AD forrest
setupADForrest -computername $computername -password $password