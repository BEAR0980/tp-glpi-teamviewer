<?php
// /etc/glpi/local_define.php
//
// Données (documents, sessions, cache) et journaux de GLPI rangés hors du
// dossier web, aux emplacements standard de Linux :
//   /etc/glpi            -> configuration (dont la connexion à la base)
//   /var/lib/glpi/files  -> données
//   /var/log/glpi        -> journaux
//
// Attention au point-virgule en fin de ligne : sans lui, PHP plante sur
// « syntax error, unexpected end of file » et GLPI ne s'affiche plus.
// Vérification : php -l /etc/glpi/local_define.php

define('GLPI_VAR_DIR', '/var/lib/glpi/files');
define('GLPI_LOG_DIR', '/var/log/glpi');
