-- Script d'initialisation pour la base de données Dolibarr
-- Ce script est exécuté uniquement lors de la première création du conteneur

-- Créer la base de données si elle n'existe pas (généralement créée par les variables d'environnement)
-- CREATE DATABASE IF NOT EXISTS dolibarr CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Accorder les privilèges (généralement fait automatiquement)
-- GRANT ALL PRIVILEGES ON dolibarr.* TO 'dolibarr'@'%';
-- FLUSH PRIVILEGES;

-- Note: Dans un environnement de production, ces opérations sont gérées
-- automatiquement par les variables d'environnement du conteneur MariaDB

