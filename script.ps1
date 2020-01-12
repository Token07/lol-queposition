$PBELogDir = "C:\Riot Games\PBE\Logs\LeagueClient Logs"

$minDate = [DateTime]::new(0)
$logfileToRead = $null
$lastQueuePosition = $null
$lastQueuePositionTime = $null

$contents = Get-ChildItem -Path $PBELogDir

foreach ($childItem in $contents)
{
    if ($childItem.Name -like "*LeagueClient.log")
    {
        Write-Host "Found potential match $($childItem.Name)"
        $logfileDate = [DateTime]::ParseExact($childItem.Name.Substring(0, 19), "yyyy-MM-ddTHH-mm-ss", $null)
        if ($logfileDate -gt $minDate)
        {
            $logfileToRead = $childItem.Name
            $minDate = $logfileDate
        }
    }
}
if ($null -ne $logfileToRead)
{
    Get-Content ($PBELogDir + "\" + $logfileToRead) -Tail 30 -Wait | % `
    { 
        if ($_ -match "(?<eventTime>\d+)\....\| ALWAYS\|           rcp-be-lol-login\| Login queue position is (?<position>\d+)")
        {
            Write-Host "Current position is:" $([string]$Matches.position)
            if ( ( ($null -ne $lastQueuePosition) -or ($null -ne $lastQueuePositionTime) ) -and ($lastQueuePosition -gt $Matches.position) )
            {
                $averageMoment = ($lastQueuePosition - [int] $matches.position) / ([int] $matches.eventTime - $lastQueuePositionTime)
                Write-Host "Average movement per second:" $averageMoment

                $etrHrs = [int] [math]::floor($Matches.position / $averageMoment / 60 / 60)
                $etrMins = [int] [math]::floor($Matches.position / $averageMoment / 60) % 60
                $etrSecs = [int] [math]::floor($Matches.position % 60)
                $etrFormatted = "{0:#00}:{1:#00}:{2:#00}" -f $etrHrs, $etrMins, $etrSecs
                Write-Host "Estimated time remaining:" $etrFormatted 
            }
            $lastQueuePositionTime = [int] $matches.eventTime
            $lastQueuePosition = [int] $Matches.position
            Write-Host `n
        }
    }
}
