# Guide d'Installation - DevSecOps Dolibarr

Ce guide décrit l'installation complète de l'environnement DevSecOps pour Dolibarr ERP/CRM.

## Prérequis Système

### Serveur Linux

- **OS** : Ubuntu 22.04 LTS ou Debian 11/12
- **RAM** : Minimum 4GB (recommandé 8GB+)
- **CPU** : 2 cores minimum (recommandé 4+)
- **Disque** : 50GB minimum d'espace libre
- **Réseau** : Accès Internet pour télécharger les images

### Logiciels Requis

```bash
# Docker
Docker Engine >= 20.10
Docker Compose >= 2.0

# Git
Git >= 2.30

# GitLab Runner (si auto-hébergé)
GitLab Runner >= 15.0
```

## Installation des Prérequis

### 1. Installation de Docker

#### Ubuntu/Debian

```bash
# Mettre à jour le système
sudo apt-get update
sudo apt-get upgrade -y

# Installer les dépendances
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Ajouter la clé GPG de Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Ajouter le dépôt Docker
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Installer Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Démarrer Docker
sudo systemctl enable docker
sudo systemctl start docker

# Vérifier l'installation
docker --version
docker compose version
```

### 2. Installation de GitLab Runner (Optionnel - Auto-hébergé)

```bash
# Télécharger et installer GitLab Runner
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash
sudo apt-get install gitlab-runner

# Enregistrer le runner (voir section Configuration GitLab Runner)
sudo gitlab-runner register
```

### 3. Installation de SonarQube (Optionnel - Auto-hébergé)

```bash
# Créer le répertoire de données
sudo mkdir -p /opt/sonarqube/data /opt/sonarqube/extensions /opt/sonarqube/logs /opt/sonarqube/temp
sudo chown -R 999:999 /opt/sonarqube

# Créer docker-compose pour SonarQube
cat <<EOF | sudo tee /opt/sonarqube/docker-compose.yml
version: '3.8'
services:
  sonarqube:
    image: sonarqube:community
    container_name: sonarqube
    environment:
      - SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true
    volumes:
      - /opt/sonarqube/data:/opt/sonarqube/data
      - /opt/sonarqube/extensions:/opt/sonarqube/extensions
      - /opt/sonarqube/logs:/opt/sonarqube/logs
      - /opt/sonarqube/temp:/opt/sonarqube/temp
    ports:
      - "9000:9000"
    restart: always
EOF

# Démarrer SonarQube
cd /opt/sonarqube
sudo docker compose up -d
```

Accéder à SonarQube : `http://localhost:9000`
- Utilisateur par défaut : `admin`
- Mot de passe par défaut : `admin` (à changer au premier login)

## Installation de Dolibarr

### 1. Cloner le Repository

```bash
# Cloner le repository
git clone https://github.com/Dolibarr/dolibarr.git
cd dolibarr

# Ou cloner depuis votre repository GitLab
git clone https://gitlab.com/votre-groupe/dolibarr.git
cd dolibarr
```

### 2. Configuration de l'Environnement

#### Variables d'environnement de développement

```bash
# Créer le fichier .env pour le développement
cat <<EOF > .env.dev
MYSQL_ROOT_PASSWORD=dev_root_password_change_me
MYSQL_DATABASE=dolibarr
MYSQL_USER=dolibarr
MYSQL_PASSWORD=dev_password_change_me
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=admin_change_me
EOF
```

#### Variables d'environnement de production

```bash
# Créer le fichier .env pour la production
cat <<EOF > .env.prod
MYSQL_ROOT_PASSWORD=<strong-password-generate>
MYSQL_DATABASE=dolibarr
MYSQL_USER=dolibarr
MYSQL_PASSWORD=<strong-password-generate>
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=<strong-password-generate>
VERSION=latest
REGISTRY_URL=registry.example.com:5000
EOF

# Générer des mots de passe forts
openssl rand -base64 32
```

### 3. Construction des Images Docker

```bash
# Construire l'image pour le développement
docker compose -f docker-compose.dev.yml build

# Ou pour la production
docker compose -f docker-compose.prod.yml build
```

### 4. Démarrage de l'Environnement

#### Environnement de développement

```bash
# Démarrer tous les services
docker compose -f docker-compose.dev.yml up -d

# Vérifier les services
docker compose -f docker-compose.dev.yml ps

# Voir les logs
docker compose -f docker-compose.dev.yml logs -f
```

#### Environnement de production

```bash
# Charger les variables d'environnement
source .env.prod

# Démarrer tous les services
docker compose -f docker-compose.prod.yml up -d

# Vérifier les services
docker compose -f docker-compose.prod.yml ps

# Voir les logs
docker compose -f docker-compose.prod.yml logs -f
```

### 5. Installation Initiale de Dolibarr

1. **Accéder à l'interface web** : `http://localhost:8080` (dev) ou `http://votre-serveur` (prod)

2. **Suivre l'assistant d'installation** :
   - Sélectionner la langue
   - Configurer la base de données :
     - Host : `mysql` (nom du service Docker)
     - Port : `3306`
     - Database : `dolibarr` (ou celle définie dans MYSQL_DATABASE)
     - User : `dolibarr` (ou celui défini dans MYSQL_USER)
     - Password : Le mot de passe défini dans MYSQL_PASSWORD

3. **Créer le compte administrateur**

4. **Finir l'installation**

## Configuration GitLab CI/CD

### 1. Configuration des Variables GitLab

Dans GitLab, aller à **Settings > CI/CD > Variables** et ajouter :

| Variable | Valeur | Protégée | Masquée |
|----------|--------|----------|---------|
| `SONARQUBE_URL` | `http://sonarqube.example.com:9000` | Non | Non |
| `SONARQUBE_TOKEN` | `<token-sonarqube>` | Oui | Oui |
| `MYSQL_ROOT_PASSWORD` | `<password>` | Oui | Oui |
| `MYSQL_PASSWORD` | `<password>` | Oui | Oui |
| `GRAFANA_ADMIN_PASSWORD` | `<password>` | Oui | Oui |

### 2. Configuration du GitLab Runner

#### Runner avec Docker Executor

```toml
# /etc/gitlab-runner/config.toml

[[runners]]
  name = "docker-runner"
  url = "https://gitlab.com/"
  token = "<runner-token>"
  executor = "docker"
  [runners.docker]
    image = "docker:24-dind"
    privileged = true
    volumes = ["/var/run/docker.sock:/var/run/docker.sock", "/cache"]
  [runners.cache]
    [runners.cache.s3]
    [runners.cache.gcs]
```

### 3. Vérification du Pipeline

```bash
# Pousser le code dans GitLab
git push origin develop

# Vérifier le pipeline dans GitLab
# Aller à CI/CD > Pipelines
```

## Configuration SonarQube

### 1. Créer un Projet dans SonarQube

1. Se connecter à SonarQube : `http://sonarqube.example.com:9000`
2. Aller à **Projects > Create Project**
3. Choisir **Manually**
4. Project key : `dolibarr`
5. Display name : `Dolibarr ERP/CRM`
6. Générer un token : **My Account > Security > Generate Token**

### 2. Configurer le Quality Gate

1. Aller à **Quality Gates**
2. Créer ou éditer un Quality Gate pour Dolibarr
3. Ajouter les conditions :
   - Coverage > 80%
   - Duplications < 3%
   - Security Hotspots Reviewed = 100%
   - Vulnerabilities = 0 (Critical et High)

## Vérification de l'Installation

### 1. Vérifier les Services Docker

```bash
# Vérifier que tous les services sont actifs
docker compose -f docker-compose.prod.yml ps

# Devrait afficher :
# - dolibarr-prod (healthy)
# - dolibarr-mysql-prod (healthy)
# - dolibarr-prometheus (healthy)
# - dolibarr-grafana (healthy)
```

### 2. Vérifier les Endpoints

```bash
# Dolibarr
curl -I http://localhost

# Prometheus
curl -I http://localhost:9090

# Grafana
curl -I http://localhost:3000
```

### 3. Vérifier les Logs

```bash
# Logs de l'application
docker compose -f docker-compose.prod.yml logs dolibarr

# Logs de la base de données
docker compose -f docker-compose.prod.yml logs mysql

# Logs de Prometheus
docker compose -f docker-compose.prod.yml logs prometheus
```

### 4. Vérifier le Pipeline CI/CD

1. Aller dans GitLab > CI/CD > Pipelines
2. Vérifier que tous les jobs passent
3. Vérifier les rapports de sécurité

## Dépannage

### Problème : Les containers ne démarrent pas

```bash
# Vérifier les logs
docker compose logs

# Vérifier les ressources
docker stats

# Redémarrer les services
docker compose restart
```

### Problème : Erreur de connexion à la base de données

```bash
# Vérifier que MySQL est démarré
docker compose ps mysql

# Vérifier les logs MySQL
docker compose logs mysql

# Tester la connexion
docker compose exec mysql mysql -u dolibarr -p
```

### Problème : SonarQube ne fonctionne pas

```bash
# Vérifier les logs
docker logs sonarqube

# Vérifier les permissions
sudo chown -R 999:999 /opt/sonarqube
```

### Problème : Pipeline CI/CD échoue

1. Vérifier les variables GitLab CI/CD
2. Vérifier la configuration du GitLab Runner
3. Vérifier les logs du runner : `sudo gitlab-runner logs`

## Prochaines Étapes

1. **Sécuriser l'environnement** : Changer tous les mots de passe par défaut
2. **Configurer les sauvegardes** : Mettre en place un plan de backup
3. **Configurer le monitoring** : Vérifier les alertes dans Grafana
4. **Documenter** : Documenter les procédures spécifiques à votre environnement

## Support

Pour toute question ou problème :
- Consulter la documentation : `docs/`
- Vérifier les issues GitLab
- Contacter l'équipe DevSecOps

