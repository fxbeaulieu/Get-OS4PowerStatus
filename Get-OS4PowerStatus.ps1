#!/snap/bin/powershell
$Global:currentFileTime = (Get-Date -Format FileDateTime)
Set-Location -Path $PSScriptRoot
$Global:PanneStatutNew = 'N'
$Global:PanneStatutAssigned = 'A'
$Global:PanneStatutWorking = 'L'
$Global:PanneStatutEnRoute = 'R'

$Global:PanneRaisonsBris = @(11, 12, 13, 14, 15, 58, 70, 72, 73, 74, 79, 'default')
$Global:PanneRaisonsMeteo = @(21, 22, 24, 25, 26)
$Global:PanneRaisonsAccident = @(31, 32, 33, 34, 41, 42, 43, 44, 54, 55, 56, 57)
$Global:PanneRaisonsVegetation = @(51)
$Global:PanneRaisonsAnimal = @(52, 53)

$Global:HydroTimeStampVar = (Invoke-WebRequest -Uri 'http://pannes.hydroquebec.com/pannes/donnees/v3_0/bisversion.json').Content.ToString()
$Global:HydroTimeStampVar = $Global:HydroTimeStampVar.Replace('"','')
$Global:HydroDataRequestURL = ("http://pannes.hydroquebec.com/pannes/donnees/v3_0/bismarkers" + "$Global:HydroTimeStampVar" + ".json")

$Global:HydroDataRequest = (Invoke-WebRequest -Uri $Global:HydroDataRequestURL)
$Global:HydroData = ConvertFrom-Json -InputObject $Global:HydroDataRequest.Content

$Global:OS4Latitude = "45.55036533571045"
$Global:OS4Longitude = "-73.63072068425883"

foreach ($Global:Panne in $Global:HydroData.pannes)
{
    if (($Global:Panne[4] -contains "$Global:OS4Latitude") -and ($Global:Panne[4] -contains "$Global:OS4Longitude"))
    {

        if ($Global:Panne[3] -is 'P')
        {
            $Global:PanneID = $Global:Panne[9]
            $Global:PanneStartTime = $Global:Panne[1]
            $Global:PanneEndETATime = $Global:Panne[2]
            $Global:PanneStatusCode = $Global:Panne[5]
            $Global:PanneRaisonCode = $Global:Panne[7]

            switch ($Global:PanneStatusCode) {
                ($_ -like $Global:PanneStatutNew) { $Global:PanneStatusString = "Nouvellement signalée" }
                ($_ -like $Global:PanneStatutAssigned) { $Global:PanneStatusString = "Travaux de réparation assignés" }
                ($_ -like $Global:PanneStatutWorking) { $Global:PanneStatusString = "Équipe au travail" }
                ($_ -like $Global:PanneStatutEnRoute) { $Global:PanneStatusString = "Équipe en route" }
                Default {$Global:PanneStatusString = "Inconnu" }
            }

            switch ($Global:PanneRaisonCode) {
                ($_ -in $Global:PanneRaisonsBris) { $Global:PanneRaisonString = "Bris d’équipement" }
                ($_ -in $Global:PanneRaisonsMeteo) { $Global:PanneRaisonString = "Conditions météorologiques" }
                ($_ -in $Global:PanneRaisonsAccident) { $Global:PanneRaisonString = "Accident ou incident" }
                ($_ -in $Global:PanneRaisonsVegetation) { $Global:PanneRaisonString = "Dommages dus à la végétation" }
                ($_ -in $Global:PanneRaisonsAnimal) { $Global:PanneRaisonString = "Dommages dus à un animal" }
                Default { $Global:PanneRaisonString = "Inconnue" }
            }

            $Global:PanneCompleteData = @($Global:PanneID,$Global:PanneStartTime,$Global:PanneEndETATime,$Global:PanneStatusString,$Global:PanneRaisonString)
            Copy-Item -Path './outages/template.csv' -Destination "./outages/$Global:currentFileTime.csv" -Force
            $Global:PanneCSV = Get-Item -Path "./outages/$Global:currentFileTime.csv"
            Add-Content -Path $Global:PanneCSV -Value ($Global:PanneCompleteData[0].ToString()+";"+$Global:PanneCompleteData[1].ToString()+";"+$Global:PanneCompleteData[2].ToString()+";"+$Global:PanneCompleteData[3].ToString()+";"+$Global:PanneCompleteData[4].ToString()) -Force
            Copy-Item -Path $Global:PanneCSV -Destination "./outages/lastcheck.csv" -Force
        }

    }
}

$Global:PanneDetectedVar = Test-Path Variable:PanneCompleteData
if ($Global:PanneDetectedVar -eq $false)
{
    $Global:PanneCompleteData = @($Global:PanneID,$Global:PanneStartTime,$Global:PanneEndETATime,$Global:PanneStatusString,$Global:PanneRaisonString)
    Copy-Item -Path './outages/template.csv' -Destination "./outages/$Global:currentFileTime.csv" -Force
    $Global:PanneCSV = Get-Item -Path "./outages/$Global:currentFileTime.csv"
    Add-Content -Path $Global:PanneCSV -Value ('Pas de panne en cours pour OS4MTL'+";"+'N/A'+";"+'N/A'+";"+'N/A'+";"+'N/A') -Force
    Copy-Item -Path $Global:PanneCSV -Destination "./outages/lastcheck.csv" -Force
}
Write-Output $Global:PanneCompleteData
Write-Output $Global:PanneCompleteDataCSV
Remove-Variable -Name PanneCompleteData -Scope Global -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
Remove-Variable -Name PanneCSV -Scope Global -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
Remove-Variable -Name PanneID -Scope Global -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
Remove-Variable -Name PanneStartTime -Scope Global -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
Remove-Variable -Name PanneEndETATime -Scope Global -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
Remove-Variable -Name PanneStatusCode -Scope Global -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
Remove-Variable -Name PanneRaisonCode -Scope Global -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue