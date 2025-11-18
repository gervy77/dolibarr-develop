#!/bin/sh
set -e

# Attendre que les services soient prêts (si nécessaire)
# Cette fonction peut être étendue pour attendre la base de données

# Créer les répertoires nécessaires si ils n'existent pas
mkdir -p /var/www/documents /var/log/nginx /var/log/php /run/nginx \
    /var/lib/nginx/tmp/client_body /var/lib/nginx/tmp/proxy \
    /var/lib/nginx/tmp/fastcgi /var/lib/nginx/tmp/uwsgi \
    /var/lib/nginx/tmp/scgi

# Vérifier les permissions (exécuter en root pour permettre supervisor de démarrer les services)
if [ -d "/var/www/html" ]; then
    chown -R dolibarr:dolibarr /var/www/html /var/www/documents 2>/dev/null || true
fi

# Permissions pour Nginx (nécessite root pour démarrer)
chown -R root:root /var/lib/nginx /run/nginx /var/log/nginx 2>/dev/null || true
chmod -R 755 /var/lib/nginx /run/nginx 2>/dev/null || true

# Permissions pour PHP-FPM logs
mkdir -p /var/log/php 2>/dev/null || true
chown -R dolibarr:dolibarr /var/log/php 2>/dev/null || true
chmod -R 755 /var/log/php 2>/dev/null || true

# Créer le fichier de verrouillage si nécessaire (pour éviter les installations non autorisées)
# Cette ligne est commentée car elle doit être gérée par l'application
# touch /var/www/documents/install.lock 2>/dev/null || true

# Exécuter le script parent (supervisord)
exec "$@"

