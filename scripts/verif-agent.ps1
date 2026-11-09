# À lancer sur un poste Windows (PC-ADMIN ou PC-CLIENT) : vérifie que l'agent
# GLPI tourne, qu'il vise la bonne adresse et que son dernier inventaire est
# bien parti. PowerShell en administrateur (lecture de HKLM et du journal).
# Usage : powershell -ExecutionPolicy Bypass -File .\verif-agent.ps1

$Serveur  = "10.50.0.10"
$UrlInv   = "http://$Serveur/front/inventory.php"
$Journal  = "C:\Program Files\GLPI-Agent\logs\glpi-agent.log"
$script:Echec = 0

function Ok($m) { Write-Host "  [OK] " -ForegroundColor Green -NoNewline; Write-Host $m }
function Ko($m) { Write-Host "  [KO] " -ForegroundColor Red   -NoNewline; Write-Host $m; $script:Echec = 1 }
function Check($m, [scriptblock]$test) { try { if (& $test) { Ok $m } else { Ko $m } } catch { Ko $m } }

function CodeHttp($url) {
  try   { (Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 5).StatusCode }
  catch { if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 0 } }
}

Write-Host "== Réseau =="
Check "Serveur GLPI joignable sur le port 80" { (Test-NetConnection $Serveur -Port 80 -WarningAction SilentlyContinue).TcpTestSucceeded }
$code = CodeHttp $UrlInv
Check "URL d'inventaire présente (HTTP $code, tout sauf 404)" { $code -ne 404 -and $code -ne 0 }

Write-Host "== Agent =="
$svc = Get-Service glpi-agent -ErrorAction SilentlyContinue
Check "Service glpi-agent démarré"             { $svc -and $svc.Status -eq "Running" }
Check "Service glpi-agent en démarrage auto"   { $svc -and $svc.StartType -eq "Automatic" }
$url = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\GLPI-Agent" -Name server -ErrorAction SilentlyContinue
Check "Adresse du serveur : $url"              { $url -eq $UrlInv }
Check "Écoute sur 62354/tcp"                   { Get-NetTCPConnection -LocalPort 62354 -State Listen -ErrorAction SilentlyContinue }
Check "Page http://localhost:62354"            { (CodeHttp "http://localhost:62354") -eq 200 }

Write-Host "== Dernier inventaire =="
if (Test-Path $Journal) {
  $ligne = Select-String -Path $Journal -Pattern "New inventory from" | Select-Object -Last 1
  if ($ligne) { Ok $ligne.Line.Trim() } else { Ko "Aucun inventaire envoyé dans $Journal" }
  $erreur = Select-String -Path $Journal -Pattern "\[error\]" | Select-Object -Last 1
  if ($erreur) { Write-Host "  Dernière erreur : $($erreur.Line.Trim())" -ForegroundColor Yellow }
} else {
  Ko "Journal introuvable : $Journal"
}

exit $script:Echec
