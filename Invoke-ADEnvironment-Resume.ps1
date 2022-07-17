Import-Module PSWorkflow

Get-Job -Command "Build-ADForrest" | Resume-Job