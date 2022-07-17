$taskName = "Test"
$taskExecute = “$($Env:SystemRoot)\System32\WindowsPowerShell\v1.0\powershell.exe”
$taskArgument = "-NonInteractive -WindowStyle Normal -NoLogo -NoProfile -NoExit -Command `“&`”$($env:PSScriptRoot)\reportstest-resume.ps1`”"

# Remove task if exists
Get-ScheduledTask -TaskName $taskName | Unregister-ScheduledTask -Confirm:$false

# Setup task
$taskAction = New-ScheduledTaskAction -Execute $taskExecute -Argument $taskArgument
$taskTrigger = New-ScheduledTaskTrigger -AtStartUp
$params = @{
	TaskName = $taskName
	Action   = $taskAction
	Trigger  = $taskTrigger
	RunLevel = "Highest"
}

# Register Task
Register-ScheduledTask @params
