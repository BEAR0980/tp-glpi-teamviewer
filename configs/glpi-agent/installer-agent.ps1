# Installation silencieuse de GLPI Agent 1.21 sur un poste Windows
# (PC-ADMIN et PC-CLIENT). À lancer dans un PowerShell en administrateur,
# depuis le dossier qui contient le .msi.
#
# Téléchargement : https://github.com/glpi-project/glpi-agent/releases
#   -> GLPI-Agent-1.21-x64.msi
#
# Équivalent de l'assistant graphique : écran « Choose Targets », champ
# Remote Targets = adresse ci-dessous, case « Quick installation » cochée.

$Msi     = ".\GLPI-Agent-1.21-x64.msi"
$Serveur = "http://10.50.0.10/front/inventory.php"   # pas de /glpi devant

if (-not (Test-Path $Msi)) { Write-Error "Fichier $Msi introuvable"; exit 1 }

$arguments = @(
  "/i", $Msi, "/quiet",
  "SERVER=`"$Serveur`"",
  "RUNNOW=1",                                  # premier inventaire tout de suite
  "ADD_FIREWALL_EXCEPTION=1",                  # ouvre le port 62354 dans le pare-feu Windows
  "TRUSTED_IP=`"127.0.0.1/32,10.50.0.0/24`""   # qui a le droit de piloter l'agent
)
Start-Process msiexec.exe -ArgumentList $arguments -Wait

Get-Service glpi-agent | Format-Table Name, Status, StartType
Write-Host "Vérification : http://localhost:62354 puis « Force an Inventory »"
