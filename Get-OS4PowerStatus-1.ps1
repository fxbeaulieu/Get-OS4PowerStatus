#!/snap/bin/powershell
$Global:currentFileTime = (Get-Date -Format FileDateTime)

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
$Global:HydroDataRequestURL = ("http://pannes.hydroquebec.com/pannes/donnees/v3_0/bismarkers" + "Global:$HydroTimeStampVar" + ".json")

$Global:HydroDataRequest = (Invoke-WebRequest -Uri $Global:HydroDataRequestURL)
$Global:HydroData = ConvertFrom-Json -InputObject $Global:HydroDataRequest.Content

$Global:OS4Latitude = "45.55036533571045"
$Global:OS4Longitude = "-73.63072068425883"

foreach ($Panne in $Global:HydroData.pannes)
{
    if (($Panne[4] -like "$Global:OS4Latitude") -and ($Panne[4] -like "$Global:OS4Longitude"))
    {

        if ($Panne[3] -is 'P')
        {
            $Global:PanneID = $Panne[9]
            $Global:PanneStartTime = $Panne[1]
            $Global:PanneEndETATime = $Panne[2]
            $Global:PanneStatusCode = $Panne[5]
            $Global:PanneRaisonCode = $Panne[7]

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

            $Global:PanneCompleteData = New-Object -TypeName pscustomobject -Property @{'ID Panne'=$Global:PanneID;'Date de debut'=$Global:PanneStartTime;'ETA de fin'=$Global:PanneEndETATime;'Statut actuel'=$Global:PanneStatusString;'Cause de la panne'=$Global:PanneRaisonString}
            $Global:PanneCompleteDataCSV = ConvertTo-Csv -InputObject $Global:PanneCompleteData -Delimiter ';'
            New-Item -Path './outages' -Name "$Global:currentFileTime.csv" -ItemType File -Value $Global:PanneCompleteDataCSV -Force
        }

    }

    else
    {
        $Global:PanneCompleteData = New-Object -TypeName pscustomobject -Property @{'ID Panne'='Pas de panne en cours pour OS4MTL'}
        $Global:PanneCompleteDataCSV = ConvertTo-Csv -InputObject $Global:PanneCompleteData -Delimiter ';'
        New-Item -Path './outages' -Name "$Global:currentFileTime.csv" -ItemType File -Value $Global:PanneCompleteDataCSV -Force
    }

}