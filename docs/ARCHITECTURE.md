# Architecture DevSecOps pour Dolibarr ERP/CRM

## Vue d'ensemble

Ce document décrit l'architecture complète du pipeline DevSecOps mis en place pour sécuriser le déploiement de Dolibarr ERP/CRM.

## Schéma de l'Infrastructure

```
┌─────────────────────────────────────────────────────────────┐
│                     GITLAB CI/CD PIPELINE                    │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  Build   │─▶│   Test   │─▶│ Security │─▶│ Quality  │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
│                                                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                  │
│  │ Package  │─▶│  Deploy  │─▶│ Monitor  │                  │
│  └──────────┘  └──────────┘  └──────────┘                  │
│                                                               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    CONTAINER REGISTRY                        │
│              (GitLab Registry ou Privé)                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              ENVIRONNEMENT DE PRODUCTION                     │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Dolibarr   │  │   MariaDB    │  │  Prometheus  │     │
│  │  (Nginx+PHP) │◀─┤  (Database)  │  │  (Metrics)   │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│         │                                    │               │
│         │                                    ▼               │
│         │                          ┌──────────────┐         │
│         │                          │   Grafana    │         │
│         │                          │ (Dashboards) │         │
│         │                          └──────────────┘         │
│         │                                    │               │
│         └────────────────────────────────────┘               │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Composants de l'Infrastructure

### 1. Pipeline GitLab CI/CD

#### Stages du Pipeline

1. **Build** : Construction des images Docker
2. **Test** : Tests de syntaxe PHP et validation des dépendances
3. **Security** : Analyses de sécurité (SAST, DAST, container scanning)
4. **Quality** : Analyse de qualité du code avec SonarQube
5. **Package** : Empaquetage des artefacts
6. **Deploy** : Déploiement en environnement de développement/production

#### Outils de Sécurité Intégrés

- **Semgrep** : Analyse statique de code (SAST)
- **Trivy** : Scan de vulnérabilités (containers, dépendances, Dockerfiles)
- **SonarQube** : Analyse de qualité et vulnérabilités de sécurité
- **GitLab Security Scanning** : Rapports intégrés de sécurité

### 2. Containerisation

#### Architecture Docker

- **Image de base** : `php:8.1-fpm-alpine` (optimisée pour la taille)
- **Web Server** : Nginx (reverse proxy)
- **Application Server** : PHP-FPM
- **Process Manager** : Supervisor

#### Bonnes Pratiques Appliquées

- Multi-stage build pour réduire la taille de l'image
- Utilisateur non-root (dolibarr:1000)
- Pas de secrets dans l'image
- Healthchecks configurés
- Labels de sécurité appliqués

### 3. Base de Données

- **SGBD** : MariaDB 10.11
- **Charset** : UTF8MB4
- **Persistance** : Volumes Docker
- **Backup** : À configurer séparément

### 4. Monitoring et Observabilité

#### Prometheus

- Collecte des métriques applicatives
- Collecte des métriques système
- Collecte des métriques de base de données
- Rétention : 30 jours

#### Grafana

- Dashboards de visualisation
- Alertes configurées
- Métriques suivies :
  - Temps de réponse
  - Taux d'erreur
  - Utilisation des ressources
  - Connexions base de données

### 5. Sécurité

#### Mesures de Sécurité Implémentées

1. **Images Docker** :
   - Scan des vulnérabilités avec Trivy
   - Images minimales (Alpine Linux)
   - Utilisateur non-root
   - Pas de privilèges inutiles

2. **Application** :
   - Headers de sécurité HTTP
   - Protection des fichiers sensibles
   - Configuration PHP sécurisée
   - Exposition PHP désactivée

3. **Réseau** :
   - Isolation des réseaux Docker
   - Communication interne uniquement
   - Ports exposés minimalistes

4. **Base de Données** :
   - Accès limité au réseau interne
   - Mots de passe forts (via variables d'environnement)
   - Charset sécurisé (UTF8MB4)

## Flux de Déploiement

### Développement

1. Commit dans la branche `develop`
2. Pipeline automatique :
   - Build de l'image
   - Tests de syntaxe
   - Scan de sécurité
   - Analyse SonarQube
3. Déploiement manuel en développement si validation OK

### Production

1. Merge dans la branche `main`/`master`
2. Pipeline complet avec validation de sécurité
3. Scan des images Docker obligatoire
4. Quality Gate SonarQube doit passer
5. Déploiement manuel en production après validation

## Décisions Techniques

### Pourquoi Alpine Linux ?

- Taille d'image réduite (~50MB vs ~200MB)
- Moins de surface d'attaque
- Mises à jour de sécurité fréquentes

### Pourquoi PHP-FPM avec Nginx ?

- Performance supérieure à Apache
- Configuration plus flexible
- Meilleure gestion des connexions
- Support natif de PHP-FPM

### Pourquoi MariaDB ?

- Compatibilité MySQL
- Performances améliorées
- Open source
- Support de la communauté

### Pourquoi Prometheus/Grafana ?

- Standard de l'industrie
- Open source
- Extensible
- Intégration facile

## Scalabilité

L'architecture est conçue pour être scalable :

- **Horizontal Scaling** : Plusieurs instances Dolibarr derrière un load balancer
- **Database Scaling** : Réplication MariaDB (master-slave)
- **Storage Scaling** : Volumes partagés pour les documents

## Haute Disponibilité

Pour une mise en production haute disponibilité :

1. Load balancer devant plusieurs instances
2. Base de données en cluster (MariaDB Galera)
3. Stockage partagé pour les documents
4. Monitoring et alertes actifs
5. Procédures de backup/restore testées

## Sécurité

### Secrets Management

- Variables GitLab CI/CD pour les secrets
- Pas de secrets dans le code source
- Rotation des secrets régulière
- Audit des accès

### Gestion des Vulnérabilités

- Scan automatique à chaque commit
- Blocage du déploiement en cas de vulnérabilité critique
- Documentation des vulnérabilités acceptées
- Plan de mitigation pour les vulnérabilités moyennes

## Maintenance

### Mises à Jour

- Images de base mises à jour régulièrement
- Scan de sécurité après chaque mise à jour
- Tests de régression avant déploiement
- Rollback planifié

### Monitoring

- Alertes sur les incidents critiques
- Dashboard de suivi quotidien
- Rapports mensuels de sécurité
- Audit trimestriel

