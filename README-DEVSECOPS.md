# DevSecOps pour Dolibarr ERP/CRM

## Vue d'ensemble

Ce projet implémente un pipeline DevSecOps complet pour le déploiement sécurisé de Dolibarr ERP/CRM. Il inclut la containerisation, l'automatisation CI/CD, les analyses de sécurité, et le monitoring.

## 🚀 Fonctionnalités

### Infrastructure Containerisée

- ✅ Dockerfile optimisé avec Alpine Linux
- ✅ Multi-stage build pour réduire la taille
- ✅ Utilisateur non-root pour la sécurité
- ✅ Configuration Nginx + PHP-FPM
- ✅ docker-compose pour dev et prod

### Pipeline GitLab CI/CD

- ✅ Build automatisé des images Docker
- ✅ Tests de syntaxe PHP
- ✅ Validation des dépendances
- ✅ Scan de sécurité (SAST, container, dépendances)
- ✅ Analyse de qualité avec SonarQube
- ✅ Déploiement automatisé

### Outils de Sécurité Intégrés

- ✅ **Semgrep** : Analyse statique de code (SAST)
- ✅ **Trivy** : Scan de vulnérabilités (containers, dépendances, Dockerfiles)
- ✅ **SonarQube** : Analyse de qualité et sécurité
- ✅ **GitLab Security Scanning** : Rapports intégrés

### Monitoring et Observabilité

- ✅ **Prometheus** : Collecte de métriques
- ✅ **Grafana** : Dashboards de visualisation
- ✅ **Alertmanager** : Gestion des alertes
- ✅ Métriques applicatives, système et base de données

## 📁 Structure du Projet

```
.
├── Dockerfile                      # Image Docker optimisée
├── docker-compose.yml              # Configuration Docker Compose unique (profils: dev, prod, monitoring)
├── .gitlab-ci.yml                  # Pipeline CI/CD
├── sonar-project.properties        # Configuration SonarQube
├── .dockerignore                   # Fichiers exclus du build
├── docker/                         # Configurations Docker
│   ├── nginx/                      # Configuration Nginx
│   ├── mysql/                      # Configuration MySQL
│   ├── prometheus/                 # Configuration Prometheus
│   ├── grafana/                    # Configuration Grafana
│   ├── supervisor/                 # Configuration Supervisor
│   └── scripts/                    # Scripts utilitaires
└── docs/                           # Documentation
    ├── ARCHITECTURE.md             # Architecture technique
    ├── INSTALLATION.md             # Guide d'installation
    ├── USAGE.md                    # Guide d'utilisation
    ├── DOCKER-COMPOSE-USAGE.md     # Guide d'utilisation Docker Compose
    ├── BEST_PRACTICES.md           # Bonnes pratiques
    └── SECURITY_ANALYSIS.md        # Rapport d'analyse de sécurité
```

## 🏗️ Architecture

### Pipeline CI/CD

```
Commit → Build → Test → Security → Quality → Package → Deploy
                                   ↓
                            SAST (Semgrep)
                            Container Scan (Trivy)
                            Dependency Scan (Trivy)
                            Code Quality (SonarQube)
```

### Infrastructure

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Dolibarr  │◀───┤   MariaDB   │    │ Prometheus  │
│ (Nginx+PHP) │    │  (Database) │    │  (Metrics)  │
└─────────────┘    └─────────────┘    └─────────────┘
       │                                      │
       └──────────────────────────────────────┘
                         │
                         ▼
                   ┌─────────────┐
                   │   Grafana   │
                   │ (Dashboards)│
                   └─────────────┘
```

## 📖 Documentation

- **[Architecture](docs/ARCHITECTURE.md)** : Description détaillée de l'architecture
- **[Installation](docs/INSTALLATION.md)** : Guide d'installation pas à pas
- **[Utilisation](docs/USAGE.md)** : Guide d'utilisation du pipeline
- **[Docker Compose](docs/DOCKER-COMPOSE-USAGE.md)** : Guide d'utilisation du fichier docker-compose.yml unique
- **[Bonnes Pratiques](docs/BEST_PRACTICES.md)** : Bonnes pratiques de sécurité
- **[Analyse de Sécurité](docs/SECURITY_ANALYSIS.md)** : Rapport d'analyse de sécurité

## 🚀 Démarrage Rapide

### Prérequis

- Docker Engine >= 20.10
- Docker Compose >= 2.0
- GitLab (ou GitLab.com)

### Installation

```bash
# Cloner le repository
git clone https://github.com/Dolibarr/dolibarr.git
cd dolibarr

# Configurer les variables d'environnement
cp .gitlab-ci-variables.example .gitlab-ci-variables
# Éditer .gitlab-ci-variables avec vos valeurs

# Démarrer l'environnement de développement
docker compose --profile dev up -d

# Accéder à Dolibarr
# http://localhost:8080

# Voir le guide complet : docs/DOCKER-COMPOSE-USAGE.md
```

### Configuration GitLab CI/CD

1. Configurer les variables dans **Settings > CI/CD > Variables**
2. Voir `.gitlab-ci-variables.example` pour la liste complète
3. Configurer SonarQube (voir `docs/INSTALLATION.md`)

## 🔒 Sécurité

### Mesures de Sécurité Implémentées

- ✅ Scan automatique des vulnérabilités
- ✅ Images Docker optimisées et sécurisées
- ✅ Utilisateur non-root
- ✅ Headers de sécurité HTTP
- ✅ Protection des fichiers sensibles
- ✅ Isolation réseau Docker
- ✅ Gestion sécurisée des secrets

### Processus de Sécurité

1. **À chaque commit** : Scans automatiques
2. **Blocage automatique** : En cas de vulnérabilité critique
3. **Rapports de sécurité** : Générés automatiquement
4. **Monitoring continu** : Métriques et alertes

## 📊 Monitoring

### Accès aux Outils

- **Dolibarr** : `http://localhost:8080` (dev) ou `http://your-server` (prod)
- **Prometheus** : `http://localhost:9090`
- **Grafana** : `http://localhost:3000`

### Métriques Surveillées

- Temps de réponse applicatif
- Taux d'erreur HTTP
- Utilisation des ressources (CPU, RAM, Disque)
- Connexions base de données
- Métriques PHP-FPM
- Métriques Nginx

## 🛠️ Développement

### Workflow

1. Créer une branche feature
2. Développer et commit
3. Pipeline automatique (tests + scans)
4. Merge Request
5. Review et validation
6. Merge et déploiement

### Tests Locaux

```bash
# Vérifier la syntaxe PHP
find htdocs -name "*.php" -exec php -l {} \;

# Construire l'image localement
docker build -t dolibarr:local .

# Tester avec docker-compose
docker compose --profile dev up
```

## 📝 Contribution

Les contributions sont les bienvenues ! Veuillez :

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/AmazingFeature`)
3. Commit vos changements (`git commit -m 'Add some AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Merge Request

## 📄 Licence

Ce projet est sous licence GPL-3.0-or-later (comme Dolibarr).

## 🙏 Remerciements

- [Dolibarr](https://www.dolibarr.org/) pour l'application ERP/CRM
- [Trivy](https://github.com/aquasecurity/trivy) pour le scan de sécurité
- [Semgrep](https://semgrep.dev/) pour l'analyse statique
- [SonarQube](https://www.sonarqube.org/) pour l'analyse de qualité
- [Prometheus](https://prometheus.io/) et [Grafana](https://grafana.com/) pour le monitoring

## 📞 Support

Pour toute question ou problème :

- Consulter la documentation : `docs/`
- Ouvrir une issue sur GitLab
- Contacter l'équipe DevSecOps

---

**Version** : 1.0.0  
**Dernière mise à jour** : 2024

