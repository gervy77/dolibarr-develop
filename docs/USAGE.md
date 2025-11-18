# Guide d'Utilisation du Pipeline DevSecOps

Ce guide décrit l'utilisation quotidienne du pipeline CI/CD et des outils de sécurité pour Dolibarr.

## Déclenchement du Pipeline

### Déclenchement Automatique

Le pipeline se déclenche automatiquement dans les cas suivants :

- **Commit sur une branche** : Le pipeline complet est exécuté
- **Merge Request** : Le pipeline de validation est exécuté
- **Tag créé** : Le pipeline de build et scan est exécuté

### Déclenchement Manuel

Dans GitLab, vous pouvez déclencher manuellement le pipeline :

1. Aller à **CI/CD > Pipelines**
2. Cliquer sur **Run pipeline**
3. Sélectionner la branche
4. Éventuellement ajouter des variables
5. Cliquer sur **Run pipeline**

### Décloiement Manuel

Les déploiements nécessitent une action manuelle pour des raisons de sécurité :

#### Développement

1. Aller à **CI/CD > Pipelines**
2. Trouver le pipeline à déployer
3. Cliquer sur le job **deploy:development**
4. Cliquer sur **Play**

#### Production

1. Aller à **CI/CD > Pipelines**
2. Trouver le pipeline validé (tous les tests passent)
3. Cliquer sur le job **deploy:production**
4. Confirmer le déploiement
5. Cliquer sur **Play**

## Interprétation des Résultats

### Stages du Pipeline

#### 1. Build

**Status attendu** : ✅ Success

- Construction de l'image Docker
- Push vers le registry

**En cas d'échec** :
- Vérifier les logs du job
- Vérifier que Docker est accessible
- Vérifier les credentials du registry

#### 2. Test

**Status attendu** : ✅ Success

- Tests de syntaxe PHP
- Validation des dépendances

**En cas d'échec** :
- Corriger les erreurs de syntaxe PHP
- Vérifier les dépendances dans `composer.json`

#### 3. Security

**Status attendu** : ✅ Success

- SAST Semgrep
- Scan des dépendances Trivy
- Scan des containers Trivy
- Scan des Dockerfiles Trivy

**En cas d'échec** :

##### Vulnérabilités Critiques

Le pipeline bloque automatiquement en cas de vulnérabilité critique. Actions :

1. Consulter le rapport de sécurité
2. Identifier la vulnérabilité
3. Corriger le code ou mettre à jour les dépendances
4. Recréer le pipeline

##### Vulnérabilités Moyennes/Élevées

Le pipeline peut continuer mais génère des alertes :

1. Consulter le rapport
2. Évaluer le risque
3. Planifier une correction
4. Documenter dans le rapport de sécurité

#### 4. Quality

**Status attendu** : ✅ Success

- Analyse SonarQube
- Quality Gate passé

**En cas d'échec** :

1. Consulter le rapport SonarQube
2. Identifier les problèmes de qualité
3. Corriger le code
4. Relancer le pipeline

#### 5. Package

**Status attendu** : ✅ Success

- Empaquetage des artefacts

**En cas d'échec** :
- Généralement lié aux étapes précédentes
- Vérifier que les scans de sécurité ont réussi

#### 6. Deploy

**Status attendu** : ✅ Success (après action manuelle)

- Déploiement en environnement cible

**En cas d'échec** :

1. Vérifier les logs de déploiement
2. Vérifier que l'environnement cible est accessible
3. Vérifier les credentials de déploiement
4. Vérifier les ressources disponibles

## Actions en Cas d'Échec

### Pipeline Bloqué par une Vulnérabilité Critique

1. **Identifier la vulnérabilité** :
   - Aller dans **Security > Vulnerability Report**
   - Identifier la CVE ou le problème

2. **Évaluer le risque** :
   - Lire la description de la vulnérabilité
   - Vérifier si elle est exploitable dans notre contexte

3. **Corriger** :
   - Mettre à jour les dépendances si possible
   - Appliquer un patch si disponible
   - Corriger le code si c'est un problème applicatif

4. **Valider** :
   - Commit et push les corrections
   - Relancer le pipeline
   - Vérifier que la vulnérabilité est corrigée

### Pipeline Bloqué par SonarQube

1. **Consulter le rapport SonarQube** :
   - Aller dans le job `quality:sonarqube`
   - Cliquer sur le lien vers SonarQube
   - Voir les issues bloquantes

2. **Corriger les problèmes** :
   - Bugs critiques/hauts
   - Vulnérabilités de sécurité
   - Code smells bloquants

3. **Relancer le pipeline**

### Déploiement Échoué

1. **Vérifier les logs** :
   ```bash
   docker compose -f docker-compose.prod.yml logs -f
   ```

2. **Vérifier l'environnement** :
   - Disque plein ?
   - Mémoire disponible ?
   - Services dépendants actifs ?

3. **Rollback si nécessaire** :
   ```bash
   # Revenir à la version précédente
   docker compose -f docker-compose.prod.yml pull dolibarr:previous-tag
   docker compose -f docker-compose.prod.yml up -d
   ```

## Processus de Validation et Déploiement

### Workflow Recommandé

```
1. Développement
   ↓
2. Commit sur branche feature
   ↓
3. Pipeline automatique (tests + scans)
   ↓
4. Merge Request vers develop
   ↓
5. Review du code + validation du pipeline
   ↓
6. Merge dans develop
   ↓
7. Pipeline complet + déploiement manuel en dev
   ↓
8. Tests en environnement de développement
   ↓
9. Merge vers main/master
   ↓
10. Pipeline complet + validation
   ↓
11. Déploiement manuel en production
```

### Checklist de Validation Avant Déploiement

- [ ] Tous les tests passent
- [ ] Aucune vulnérabilité critique
- [ ] Quality Gate SonarQube passé
- [ ] Scan des containers réussi
- [ ] Documentation à jour
- [ ] Tests en dev réussis
- [ ] Plan de rollback préparé
- [ ] Équipe notifiée du déploiement

### Processus de Déploiement en Production

1. **Pré-déploiement** :
   - Vérifier la checklist de validation
   - S'assurer qu'une sauvegarde récente existe
   - Notifier l'équipe
   - Planifier une fenêtre de maintenance si nécessaire

2. **Déploiement** :
   - Déclencher le job `deploy:production`
   - Surveiller les logs en temps réel
   - Vérifier que les services démarrent correctement

3. **Post-déploiement** :
   - Vérifier l'application fonctionne : `https://dolibarr.example.com`
   - Vérifier les métriques dans Grafana
   - Vérifier qu'aucune alerte n'est déclenchée
   - Effectuer des tests fonctionnels de base
   - Documenter le déploiement

4. **Rollback si problème** :
   - Arrêter le déploiement
   - Restaurer la version précédente
   - Investiguer le problème
   - Documenter l'incident

## Utilisation des Rapports de Sécurité

### Rapports Semgrep

1. Aller dans **Security > SAST Report**
2. Consulter les vulnérabilités trouvées
3. Voir les détails et le code concerné
4. Corriger les problèmes identifiés

### Rapports Trivy

1. Aller dans **Security > Dependency Scanning** ou **Container Scanning**
2. Filtrer par sévérité (Critical, High, Medium, Low)
3. Consulter les détails de chaque vulnérabilité
4. Vérifier si une mise à jour existe
5. Planifier la correction

### Rapports SonarQube

1. Aller dans **CI/CD > Jobs > quality:sonarqube**
2. Cliquer sur le lien vers SonarQube
3. Consulter :
   - **Issues** : Problèmes de code et sécurité
   - **Measures** : Métriques de qualité
   - **Security Hotspots** : Points de sécurité à revoir

## Monitoring en Production

### Accès à Grafana

1. URL : `http://localhost:3000` (ou votre domaine)
2. Identifiants : Définis dans les variables d'environnement
3. Dashboard : **Dolibarr Overview**

### Métriques à Surveiller

#### Temps de Réponse
- Objectif : < 500ms pour 95% des requêtes
- Alerte : > 2s pour plus de 5% des requêtes

#### Taux d'Erreur
- Objectif : < 0.1%
- Alerte : > 1%

#### Utilisation des Ressources
- CPU : Alerte si > 80% pendant 5 minutes
- Mémoire : Alerte si > 90%
- Disque : Alerte si > 85%

#### Base de Données
- Connexions : Alerte si > 80% du max
- Temps de requête : Alerte si > 1s
- Locks : Alerte si > 10

### Alertes

Les alertes sont configurées dans Prometheus et envoyées via Alertmanager.

Vérifier la configuration dans `docker/prometheus/alertmanager.yml`.

## Bonnes Pratiques

### Avant un Commit

1. Vérifier la syntaxe PHP localement
2. Lancer les tests locaux si disponibles
3. Vérifier qu'aucun secret n'est dans le code
4. Vérifier que les dépendances sont à jour

### Pendant le Développement

1. Commits fréquents et atomiques
2. Messages de commit clairs
3. Merge Requests descriptives
4. Review du code par un pair

### Après un Déploiement

1. Vérifier les logs
2. Surveiller les métriques
3. Tester les fonctionnalités critiques
4. Documenter les changements

## Support et Assistance

En cas de problème :

1. Consulter les logs du pipeline
2. Consulter la documentation
3. Vérifier les issues GitLab
4. Contacter l'équipe DevSecOps

## Glossaire

- **SAST** : Static Application Security Testing
- **DAST** : Dynamic Application Security Testing
- **CVE** : Common Vulnerabilities and Exposures
- **Quality Gate** : Seuils de qualité définis dans SonarQube
- **Pipeline** : Suite d'étapes automatisées pour le déploiement
- **Registry** : Dépôt d'images Docker
- **Vulnérabilité Critique** : Vulnérabilité pouvant causer un impact grave

