param (
    [string]$src = "PUNE",
    [string]$dst = "NDLS",
    [string]$date = "06-11-2026"
)

$url = "https://cttrainsapi.confirmtkt.com/api/v1/trains/search?sourceStationCode=$src&destinationStationCode=$dst&dateOfJourney=$date"

$headers = @{
    "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    "Accept" = "application/json"
    "clientid" = "ct-web"
    "apikey" = "ct-web!2$"
    "deviceid" = "ct-mcp-0000-0000-0000-000000000000"
}

$response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get

Write-Output "Results for $src -> $dst on $date :"
foreach ($t in $response.data.trainList) {
    Write-Output "=================================================="
    Write-Output ("Train: " + $t.trainNumber + " - " + $t.trainName)
    Write-Output ("Timing: " + $t.departureTime + " -> " + $t.arrivalTime + " | Duration: " + [math]::Floor($t.duration/60) + "h " + ($t.duration % 60) + "m")
    Write-Output ("From: " + $t.fromStnCode + " -> To: " + $t.toStnCode)
    
    if ($t.availabilityCache) {
        $props = $t.availabilityCache.psobject.properties
        foreach ($p in $props) {
            $val = $p.Value
            Write-Output ("  Class: " + $p.Name + " | Status: " + $val.availabilityDisplayName + " (Raw: " + $val.availability + ") | Conf Chance: " + $val.predictionPercentage + "% | Fare: Rs." + $val.fare)
        }
    }
}
