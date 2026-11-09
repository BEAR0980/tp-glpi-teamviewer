#!/usr/bin/env bash
# Firewall (Rocky Linux, iptables, NetworkManager) — sortie Internet du segment GLPI
#
# Interfaces :
#   ens18 = WAN   (réseau de l'école, IP masquée)          vmbr0
#   ens19 = DMZ   192.168.10.254/24                        vmbr1
#   ens20 = LAN   10.20.30.254/24                          vmbr2
#   ens21 = GLPI  10.50.0.254/24   <- passerelle du TP     vmbr3
#
# Le segment 10.50.0.0/24 contient le serveur GLPI (.10) et les deux postes
# Windows (.20 admin, .30 client). Les échanges agent -> GLPI restent dans le
# segment et ne passent pas par le firewall. Le firewall ne sert qu'à la
# sortie Internet : apt, téléchargement de GLPI et de l'agent sur GitHub,
# TeamViewer (connexion sortante en 443).
#
# Chaque règle n'est ajoutée que si elle n'existe pas déjà (iptables -C),
# pour ne pas créer de doublons dans la chaîne FORWARD en relançant le script.
set -euo pipefail

WAN=ens18
GLPI=ens21
RESEAU_GLPI=10.50.0.0/24

ajoute() {   # ajoute <table> <chaîne> <règle...>
  local table=$1 chaine=$2; shift 2
  iptables -t "$table" -C "$chaine" "$@" 2>/dev/null || iptables -t "$table" -A "$chaine" "$@"
}

# 1) Routage entre les interfaces, de façon permanente
echo 'net.ipv4.ip_forward = 1' > /etc/sysctl.d/99-routage.conf
sysctl -p /etc/sysctl.d/99-routage.conf

# 2) Les réponses reviennent toujours
ajoute filter FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT

# 3) Segment GLPI -> Internet : web, DNS et ping uniquement
ajoute filter FORWARD -i "$GLPI" -o "$WAN" -p tcp -m multiport --dports 80,443 -j ACCEPT
ajoute filter FORWARD -i "$GLPI" -o "$WAN" -p udp --dport 53 -j ACCEPT
ajoute filter FORWARD -i "$GLPI" -o "$WAN" -p tcp --dport 53 -j ACCEPT
ajoute filter FORWARD -i "$GLPI" -o "$WAN" -p icmp -j ACCEPT

# 4) NAT : les machines du segment sortent avec l'adresse WAN du firewall
ajoute nat POSTROUTING -s "$RESEAU_GLPI" -o "$WAN" -j MASQUERADE

# Sauvegarde : sans ça, les règles disparaissent au redémarrage
iptables-save > /etc/sysconfig/iptables

echo "Règles en place :"
iptables -L FORWARD -n -v --line-numbers
iptables -t nat -L POSTROUTING -n -v --line-numbers
