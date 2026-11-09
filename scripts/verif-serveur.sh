#!/usr/bin/env bash
# À lancer en root sur le serveur GLPI (Debian 13) : contrôle rapide de la pile
# Apache / PHP / MariaDB / GLPI et de l'accès réseau.
# Usage : bash verif-serveur.sh

GLPI_DIR=/var/www/html/glpi
PASSERELLE=10.50.0.254

ok()  { printf '  \e[32m[OK]\e[0m %s\n' "$1"; }
ko()  { printf '  \e[31m[KO]\e[0m %s\n' "$1"; ECHEC=1; }
check() { if eval "$2" >/dev/null 2>&1; then ok "$1"; else ko "$1"; fi; }
ECHEC=0

echo "== Réseau =="
check "IP fixe 10.50.0.10 sur ens18"          "ip -4 addr show ens18 | grep -q '10.50.0.10/24'"
check "Route par défaut via $PASSERELLE"      "ip route | grep -q 'default via $PASSERELLE'"
check "Passerelle joignable"                  "ping -c1 -W2 $PASSERELLE"
check "Internet joignable (1.1.1.1)"          "ping -c1 -W2 1.1.1.1"
check "Résolution DNS (github.com)"           "getent hosts github.com"

echo "== Apache =="
check "Service apache2 actif"                 "systemctl is-active apache2"
check "Service apache2 activé au démarrage"   "systemctl is-enabled apache2"
check "Écoute sur 80/tcp"                     "ss -tlnp | grep -q ':80 .*apache2'"
check "Module rewrite chargé"                 "apache2ctl -M | grep -q rewrite_module"
check "Syntaxe de la configuration"           "apache2ctl configtest"
check "DocumentRoot sur $GLPI_DIR/public"     "grep -rqs 'DocumentRoot $GLPI_DIR/public' /etc/apache2/sites-enabled/"

echo "== PHP =="
PHPV=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null)
check "PHP entre 8.3 et 8.5 (trouvé : ${PHPV:-absent})" "php -r 'exit(version_compare(PHP_VERSION,\"8.3.0\",\">=\") && version_compare(PHP_VERSION,\"8.6.0\",\"<\") ? 0 : 1);'"
MANQUE=""
for ext in bcmath curl dom fileinfo gd intl mbstring mysqli openssl session simplexml xmlreader xmlwriter zlib; do
  php -m | grep -qix "$ext" || MANQUE="$MANQUE $ext"
done
if [ -z "$MANQUE" ]; then ok "Extensions PHP requises par GLPI"; else ko "Extensions PHP manquantes :$MANQUE"; fi

echo "== MariaDB =="
check "Service mariadb actif"                 "systemctl is-active mariadb"
check "Base glpi présente"                    "mysql -N -e \"SHOW DATABASES LIKE 'glpi'\" | grep -qx glpi"

echo "== GLPI =="
check "Version installée : $(ls "$GLPI_DIR/version" 2>/dev/null | head -1)" "test -d $GLPI_DIR/version"
check "inc/downstream.php présent (config dans /etc/glpi)" "test -f $GLPI_DIR/inc/downstream.php"
check "Syntaxe PHP de downstream.php"         "php -l $GLPI_DIR/inc/downstream.php"
check "Syntaxe PHP de /etc/glpi/local_define.php" "php -l /etc/glpi/local_define.php"
for d in /etc/glpi /var/lib/glpi/files /var/log/glpi; do
  check "$d appartient à www-data"             "test \"\$(stat -c %U $d)\" = www-data"
done
check "Script d'installation supprimé"        "test ! -e $GLPI_DIR/install/install.php"
CODE=$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1/)
check "Page d'accueil (HTTP $CODE)"           "[ '$CODE' = 200 ] || [ '$CODE' = 302 ]"
CODE=$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1/front/inventory.php)
check "URL d'inventaire présente (HTTP $CODE, tout sauf 404)" "[ '$CODE' != 404 ] && [ '$CODE' != 000 ]"

echo "== Parc =="
NB=$(mysql -N glpi -e "SELECT COUNT(*) FROM glpi_computers WHERE is_deleted = 0 AND is_template = 0" 2>/dev/null)
echo "  Ordinateurs dans le parc : ${NB:-inconnu}"
mysql -N glpi -e "SELECT CONCAT('    - ', name, ' (vu le ', last_inventory_update, ')') FROM glpi_computers WHERE is_deleted = 0 AND is_template = 0 ORDER BY name" 2>/dev/null

exit $ECHEC
