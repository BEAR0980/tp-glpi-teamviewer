# Corrige l'adresse du serveur GLPI d'un agent déjà installé, sans le
# réinstaller. Utile si l'agent a été installé en mode « Typical » (aucune
# adresse demandée) ou avec une mauvaise URL (/glpi/front/... -> 404).
# À lancer dans un PowerShell en administrateur.

$Cle     = "HKLM:\SOFTWARE\GLPI-Agent"
$Serveur = "http://10.50.0.10/front/inventory.php"

Write-Host "Avant : $(Get-ItemPropertyValue -Path $Cle -Name server -ErrorAction SilentlyContinue)"

# Tout sur une seule ligne : un guillemet oublié laisse PowerShell bloqué sur « >> »
Set-ItemProperty -Path $Cle -Name "server" -Value $Serveur

Write-Host "Après : $(Get-ItemPropertyValue -Path $Cle -Name server)"
Restart-Service -Name "glpi-agent"
