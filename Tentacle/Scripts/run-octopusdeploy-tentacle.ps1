﻿[CmdletBinding()]
Param()

. ./octopus-common.ps1


function Run-OctopusDeployTentacle
{
 if(!(Test-Path $TentacleExe)) {
	throw "File not found. Expected to find '$TentacleExe' to perform setup."
  }  
  
  Write-Log "Start Octopus Deploy Tentacle instance ..."
  Execute-Command $TentacleExe @(
    'service',
    '--console',
    '--instance', 'Tentacle',
    '--start'
  )

  "Run started." | Set-Content "c:\octopus-run.initstate"

  # try/finally is here to try and stop the server gracefully upon container stop
  try {
     # sleep-loop indefinitely (until container stop)
    $lastCheck = (Get-Date).AddSeconds(-2)
    while ($true) {
      Get-EventLog -LogName Application -Source "Octopus*" -After $lastCheck | Select-Object TimeGenerated, EntryType, Message
      $lastCheck = Get-Date
       "$([DateTime]::Now.ToShortTimeString()) - OctopusDeploy Tentacle service is '$((Get-Service "OctopusDeploy Tentacle").status)'."
       Start-Sleep -Seconds 60
    }
  }
  finally {
      Write-Log "Shutting down Octopus Deploy instance ..."
      Execute-Command $TentacleExe @(
        'service',
        '--console',
        '--instance', 'Tentacle',
        '--stop'
      )
  }

  Write-Log ""
}

try
{
  Write-Log "==============================================="
  Write-Log "Running Octopus Deploy Tentacle"
  Write-Log "==============================================="

  Run-OctopusDeployTentacle

  Write-Log "Run successful."
  Write-Log ""
}
catch
{
  Write-Log $_
  exit 2
}