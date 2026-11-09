<?php
// /var/www/html/glpi/inc/downstream.php
//
// Indique à GLPI que sa configuration n'est plus dans le dossier web,
// mais dans /etc/glpi. GLPI y lit ensuite local_define.php, qui déplace
// à leur tour les données et les journaux.

define('GLPI_CONFIG_DIR', '/etc/glpi/');

if (file_exists(GLPI_CONFIG_DIR . '/local_define.php')) {
    require_once GLPI_CONFIG_DIR . '/local_define.php';
}
