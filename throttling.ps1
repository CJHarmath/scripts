param([parameter(Mandatory=$true)]$script)


$maxJobs = 10

#$script = { start-process C:\temp\sleep.exe 5000 -Wait -WindowStyle Hidden}

$runningJobs = (get-job -State Running | Measure-Object).Count
1..100 | % { 
    $runningJobs = (get-job -State Running | Measure-Object).Count
    if ($runningJobs -lt $maxJobs)
    {
        start-job -ScriptBlock $script
    }
    else
    {
        wait-job (get-job -state Running)[0]
        start-job -ScriptBlock $script
    }
}
if ((get-job -State Running).Count -ge 1)
{
    Write-Output "waiting for all jobs to complete ... "
    wait-job (get-job -State Running)[-1]
    Write-Output "done"
}