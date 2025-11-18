# Guide d'Utilisation de Docker Compose

Ce guide explique comment utiliser le fichier `docker-compose.yml` unique avec les profils Docker Compose pour gérer les différents environnements.

## 🎯 Concept des Profils

Le fichier `docker-compose.yml` utilise des **profils Docker Compose** pour activer/désactiver différents services selon l'environnement :

- **`dev`** : Environnement de développement (Dolibarr + MySQL)
- **`prod`** : Environnement de production (Dolibarr + MySQL + Prometheus + Grafana)
- **`monitoring`** : Services de monitoring avancés (exporters, alertmanager)
- **`tools`** / **`dev-tools`** : Outils de développement (phpMyAdmin)

## 🚀 Utilisation

### Environnement de Développement

Démarrer l'environnement de développement complet :

```bash
# Démarrer Dolibarr + MySQL
docker compose --profile dev up -d

# Démarrer avec phpMyAdmin
docker compose --profile dev --profile tools up -d

# Voir les logs
docker compose --profile dev logs -f

# Arrêter
docker compose --profile dev down
```

**Services disponibles :**
- Dolibarr : http://localhost:8080
- MySQL : localhost:3306
- phpMyAdmin : http://localhost:8081 (avec profil `tools`)

### Environnement de Production

Démarrer l'environnement de production :

```bash
# Configuration des variables d'environnement (obligatoires)
export MYSQL_ROOT_PASSWORD="votre_mot_de_passe_root"
export MYSQL_PASSWORD="votre_mot_de_passe"
export REGISTRY_URL="registry.local:5000"  # Optionnel
export VERSION="latest"  # Optionnel

# Démarrer Dolibarr + MySQL + Prometheus + Grafana
docker compose --profile prod up -d

# Voir les logs
docker compose --profile prod logs -f

# Arrêter
docker compose --profile prod down
```

**Services disponibles :**
- Dolibarr : http://localhost:80
- Prometheus : http://localhost:9090
- Grafana : http://localhost:3000 (admin/admin par défaut)

### Monitoring Avancé

Ajouter les services de monitoring avancés à l'environnement de production :

```bash
# Démarrer production + monitoring complet
docker compose --profile prod --profile monitoring up -d

# Services supplémentaires disponibles :
# - Node Exporter : http://localhost:9100/metrics
# - MySQL Exporter : http://localhost:9104/metrics
# - PHP-FPM Exporter : http://localhost:9253/metrics
# - Nginx Exporter : http://localhost:9113/metrics
# - Alertmanager : http://localhost:9093
```

## 📋 Commandes Utiles

### Lister les services disponibles

```bash
# Voir tous les services configurés (avec ou sans profils)
docker compose config --services

# Voir les services actifs
docker compose ps
```

### Construire les images

```bash
# Construire l'image Dolibarr pour dev
docker compose --profile dev build dolibarr-dev

# Construire l'image Dolibarr pour prod
docker compose --profile prod build dolibarr-prod
```

### Gérer les volumes

```bash
# Lister les volumes
docker volume ls | grep dolibarr

# Inspecter un volume
docker volume inspect dolibarr_documents_dev

# Supprimer tous les volumes (⚠️ ATTENTION : supprime les données)
docker compose --profile dev down -v
docker compose --profile prod down -v
```

### Accéder aux conteneurs

```bash
# Accéder au conteneur Dolibarr (dev)
docker compose --profile dev exec dolibarr-dev sh

# Accéder à MySQL
docker compose --profile dev exec mysql-dev mysql -u dolibarr -p

# Voir les logs d'un service
docker compose --profile dev logs -f dolibarr-dev
```

## 🔧 Configuration avec Variables d'Environnement

### Fichier .env pour le développement

Créez un fichier `.env.dev` :

```bash
# MySQL
MYSQL_ROOT_PASSWORD=dev_root_password
MYSQL_DATABASE=dolibarr
MYSQL_USER=dolibarr
MYSQL_PASSWORD=dolibarr_password
```

Utilisez-le avec :

```bash
docker compose --env-file .env.dev --profile dev up -d
```

### Fichier .env pour la production

Créez un fichier `.env.prod` :

```bash
# MySQL (OBLIGATOIRE en production)
MYSQL_ROOT_PASSWORD=production_root_password_secure
MYSQL_PASSWORD=production_password_secure
MYSQL_DATABASE=dolibarr
MYSQL_USER=dolibarr

# Registry Docker
REGISTRY_URL=registry.local:5000
VERSION=1.0.0

# Grafana
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=secure_admin_password
```

Utilisez-le avec :

```bash
docker compose --env-file .env.prod --profile prod up -d
```

## 📊 Comparaison avec les Anciens Fichiers

| Ancien Fichier | Nouvelle Commande |
|----------------|-------------------|
| `docker-compose -f docker-compose.dev.yml up` | `docker compose --profile dev up` |
| `docker-compose -f docker-compose.prod.yml up` | `docker compose --profile prod up` |
| `docker-compose -f docker-compose.prod.yml -f docker-compose.monitoring.yml up` | `docker compose --profile prod --profile monitoring up` |
| `docker-compose -f docker-compose.dev.yml --profile tools up` | `docker compose --profile dev --profile tools up` |

## ⚠️ Notes Importantes

1. **Variables d'environnement en production** : Les variables `MYSQL_ROOT_PASSWORD` et `MYSQL_PASSWORD` sont **obligatoires** en production. Le conteneur ne démarrera pas sans elles.

2. **Isolation des environnements** : Les environnements `dev` et `prod` utilisent des réseaux, volumes et noms de conteneurs différents pour éviter les conflits.

3. **Profils multiples** : Vous pouvez combiner plusieurs profils :
   ```bash
   docker compose --profile prod --profile monitoring up -d
   ```

4. **Version de Docker Compose** : Cette configuration nécessite Docker Compose v2.0+ (commande `docker compose` et non `docker-compose`).

## 🔄 Migration depuis les Anciens Fichiers

Si vous aviez déjà des conteneurs/volumes avec les anciens noms :

```bash
# Arrêter les anciens conteneurs
docker compose -f docker-compose.dev.yml down
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.monitoring.yml down

# Les volumes et données sont préservés
# Vous pouvez les migrer si nécessaire

# Démarrer avec le nouveau fichier
docker compose --profile dev up -d
```

Les volumes existants seront réutilisés automatiquement grâce aux noms identiques.

