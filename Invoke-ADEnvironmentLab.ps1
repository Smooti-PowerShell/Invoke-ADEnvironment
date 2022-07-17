param (
	[Parameter(Mandatory = $True)]
	[SecureString]$DSRMPassword,

	[Parameter(Mandatory = $False)]
	[string]$DomainName = "testbed.local",

	[Parameter(Mandatory = $False)]
	[switch]$CreateTestUsers
)

Import-Module -Name .\modules\master.psm1

# Confirm we have an elevated session.
If (-NOT([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
	Throw ("You must run this from an elevated PowerShell session.")
}

# Create test user accounts in active directory
if ($CreateTestUsers) {
	# Verify credentials locally
	$creds = Get-Credential -UserName $env:UserName -Message "Local Account Password"
	$password = $creds.GetNetworkCredential().Password
	Add-Type -AssemblyName System.DirectoryServices.AccountManagement 
	$DS = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Machine)
	$credentialsValid = $DS.ValidateCredentials("smooti", $creds.GetNetworkCredential().Password)
	if ($credentialsValid -ne "True") {
		throw ("The local credentials that you have provided are invalid.")
	}

	# Create active directory credentials
	$adCreds = New-Object System.Management.Automation.PSCredential ("$($DomainName)\$env:UserName", $password)
	$adCreds | Export-Clixml -Path "C:\tempCred.xml"
	$scripty = "$($env:PSScriptRoot)\New-ADTestUsers.ps1"
	$params = @{
		TaskName     = "Test"
		TaskExecute  = “$($Env:SystemRoot)\System32\WindowsPowerShell\v1.0\powershell.exe”
		TaskArgument = "`"-NonInteractive -WindowStyle Normal -NoLogo -NoProfile -NoExit -Command `“&`”$($scripty)`”"
	}
	
	# Schedule task
	Invoke-Task @params
}

# Convert secure string to plain text
$DSRMUnencryptedPassword = ConvertFrom-SecureString -SecureString $DSRMPassword -AsPlainText

# Check password complexity
Invoke-PasswordComplexity -Password $DSRMUnencryptedPassword

# Convert plain text password to secure string
$DSRMPassword = ConvertTo-SecureString $DSRMUnencryptedPassword -AsPlainText -Force

# Setup AD forrest
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Build-ADForrest -DSRMPassword $DSRMPassword -DomainName $DomainName

# Apply changes
Restart-Computer