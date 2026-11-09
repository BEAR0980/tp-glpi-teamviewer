-- Base et utilisateur dédiés à GLPI (MariaDB, Debian 13)
-- À lancer après mysql_secure_installation :
--   mysql < configs/mariadb/creation-base.sql
--
-- GLPI ne se connecte jamais en root : son compte glpi_adm n'a des droits
-- que sur sa propre base, et seulement depuis le serveur lui-même.
--
-- Avant de lancer l'assistant web, tester le compte à la main :
--   mysql -u glpi_adm -p glpi
-- Si ça échoue ici, l'assistant affichera
-- « Access denied for user 'glpi_adm'@'localhost' ».

CREATE DATABASE IF NOT EXISTS glpi
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- Remplacer le mot de passe avant de lancer le script
CREATE USER IF NOT EXISTS 'glpi_adm'@'localhost' IDENTIFIED BY 'CHANGER_CE_MOT_DE_PASSE';

-- Si le compte existe déjà avec un autre mot de passe :
-- ALTER USER 'glpi_adm'@'localhost' IDENTIFIED BY 'CHANGER_CE_MOT_DE_PASSE';

GRANT ALL PRIVILEGES ON glpi.* TO 'glpi_adm'@'localhost';
FLUSH PRIVILEGES;
