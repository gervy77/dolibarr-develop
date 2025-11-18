#!/bin/bash

# Script de test complet pour DevSecOps Dolibarr
# Usage: ./scripts/test-all.sh [--quick] [--skip-security]

set -e

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables
QUICK=false
SKIP_SECURITY=false
FAILED_TESTS=0
PASSED_TESTS=0

# Parse arguments
for arg in "$@"; do
    case $arg in
        --quick)
            QUICK=true
            shift
            ;;
        --skip-security)
            SKIP_SECURITY=true
            shift
            ;;
        *)
            echo "Usage: $0 [--quick] [--skip-security]"
            exit 1
            ;;
    esac
done

# Fonctions utilitaires
print_header() {
    echo -e "\n${GREEN}=== $1 ===${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED_TESTS++))
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED_TESTS++))
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

check_command() {
    if command -v "$1" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Test 1: Vérifier les prérequis
print_header "Test 1: Vérification des prérequis"

if check_command docker; then
    print_success "Docker est installé"
    docker --version
else
    print_error "Docker n'est pas installé"
fi

if check_command docker-compose || docker compose version &> /dev/null; then
    print_success "Docker Compose est installé"
else
    print_error "Docker Compose n'est pas installé"
fi

if check_command php; then
    print_success "PHP est installé"
    php --version | head -1
else
    print_warning "PHP n'est pas installé (optionnel pour tests locaux)"
fi

# Test 2: Syntaxe PHP
print_header "Test 2: Vérification de la syntaxe PHP"

if check_command php; then
    SYNTAX_ERRORS=$(find htdocs -name "*.php" -type f ! -path "*/vendor/*" ! -path "*/includes/*" -exec php -l {} \; 2>&1 | grep -c "Parse error" || true)
    if [ "$SYNTAX_ERRORS" -eq 0 ]; then
        print_success "Aucune erreur de syntaxe PHP détectée"
    else
        print_error "$SYNTAX_ERRORS erreur(s) de syntaxe PHP détectée(s)"
    fi
else
    print_warning "PHP non disponible, test de syntaxe ignoré"
fi

# Test 3: Construction de l'image Docker
print_header "Test 3: Construction de l'image Docker"

if docker build -t dolibarr:test . 2>&1 | tee /tmp/docker-build.log; then
    print_success "Image Docker construite avec succès"
    
    # Vérifier la taille de l'image
    IMAGE_SIZE=$(docker images dolibarr:test --format "{{.Size}}" | head -1)
    print_success "Taille de l'image: $IMAGE_SIZE"
else
    print_error "Échec de la construction de l'image Docker"
    cat /tmp/docker-build.log | tail -20
fi

# Test 4: Tests de sécurité (si activés)
if [ "$SKIP_SECURITY" = false ]; then
    print_header "Test 4: Tests de sécurité"
    
    # Test avec Trivy (si disponible)
    if check_command trivy || docker run --rm aquasec/trivy:latest version &> /dev/null; then
        print_header "4.1: Scan Trivy de l'image Docker"
        
        if command -v trivy &> /dev/null; then
            if trivy image --severity CRITICAL --exit-code 0 dolibarr:test 2>&1 | grep -q "CRITICAL"; then
                print_error "Vulnérabilités CRITICAL détectées dans l'image"
            else
                print_success "Aucune vulnérabilité CRITICAL dans l'image"
            fi
        else
            if docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                aquasec/trivy:latest image --severity CRITICAL --exit-code 0 dolibarr:test 2>&1 | grep -q "CRITICAL"; then
                print_error "Vulnérabilités CRITICAL détectées dans l'image"
            else
                print_success "Aucune vulnérabilité CRITICAL dans l'image"
            fi
        fi
        
        print_header "4.2: Scan Trivy du Dockerfile"
        
        if command -v trivy &> /dev/null; then
            if trivy config --severity CRITICAL . 2>&1 | grep -q "CRITICAL"; then
                print_error "Problèmes CRITICAL dans le Dockerfile"
            else
                print_success "Aucun problème CRITICAL dans le Dockerfile"
            fi
        fi
    else
        print_warning "Trivy non disponible, tests de sécurité Trivy ignorés"
    fi
    
    # Test avec Semgrep (si disponible)
    if check_command semgrep; then
        print_header "4.3: Scan Semgrep"
        
        if semgrep --config=auto --error . 2>&1 | grep -q "ERROR"; then
            print_error "Vulnérabilités détectées par Semgrep"
        else
            print_success "Aucune vulnérabilité critique détectée par Semgrep"
        fi
    else
        print_warning "Semgrep non disponible, test ignoré"
    fi
else
    print_warning "Tests de sécurité ignorés (--skip-security)"
fi

# Test 5: Tests de l'environnement Docker Compose
print_header "Test 5: Tests de l'environnement Docker Compose"

# Créer un fichier .env de test si nécessaire
if [ ! -f .env.dev ]; then
    cat > .env.dev <<EOF
MYSQL_ROOT_PASSWORD=test_root_pass
MYSQL_DATABASE=dolibarr_test
MYSQL_USER=dolibarr_test
MYSQL_PASSWORD=test_pass
EOF
    print_success "Fichier .env.dev créé"
fi

# Démarrer l'environnement
print_header "5.1: Démarrage de l'environnement de développement"

if docker compose -f docker-compose.dev.yml up -d --build 2>&1 | tee /tmp/docker-compose-up.log; then
    print_success "Environnement démarré"
    
    # Attendre que les services soient prêts
    echo "Attente du démarrage des services (30 secondes)..."
    sleep 30
    
    # Vérifier l'état des services
    print_header "5.2: Vérification de l'état des services"
    
    if docker compose -f docker-compose.dev.yml ps | grep -q "healthy\|Up"; then
        print_success "Services en cours d'exécution"
        
        # Afficher l'état des services
        docker compose -f docker-compose.dev.yml ps
    else
        print_error "Problème avec les services"
        docker compose -f docker-compose.dev.yml ps
    fi
    
    # Test de l'application web
    print_header "5.3: Test de l'application web"
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 || echo "000")
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
        print_success "Application accessible (HTTP $HTTP_CODE)"
    else
        print_error "Application inaccessible (HTTP $HTTP_CODE)"
    fi
    
    # Test de la connexion à la base de données
    print_header "5.4: Test de la connexion à la base de données"
    
    if docker compose -f docker-compose.dev.yml exec -T mysql mysql -u dolibarr_test -ptest_pass -e "SELECT 1;" &> /dev/null; then
        print_success "Connexion à la base de données réussie"
    else
        print_error "Échec de la connexion à la base de données"
    fi
    
    # Test des headers de sécurité
    print_header "5.5: Test des headers de sécurité HTTP"
    
    HEADERS=$(curl -s -I http://localhost:8080 | grep -iE "(X-Frame-Options|X-Content-Type-Options|X-XSS-Protection)" || true)
    if [ -n "$HEADERS" ]; then
        print_success "Headers de sécurité présents"
        echo "$HEADERS"
    else
        print_warning "Headers de sécurité non détectés (peut être normal selon la configuration)"
    fi
    
    # Test de protection des fichiers sensibles
    print_header "5.6: Test de protection des fichiers sensibles"
    
    PROTECTED_FILE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/conf/conf.php || echo "000")
    if [ "$PROTECTED_FILE" = "403" ] || [ "$PROTECTED_FILE" = "404" ]; then
        print_success "Fichiers sensibles protégés (HTTP $PROTECTED_FILE)"
    else
        print_warning "Protection des fichiers sensibles à vérifier (HTTP $PROTECTED_FILE)"
    fi
    
    # Nettoyer après les tests (si --quick non spécifié)
    if [ "$QUICK" = false ]; then
        print_header "Nettoyage de l'environnement de test"
        docker compose -f docker-compose.dev.yml down -v
        print_success "Environnement nettoyé"
    else
        print_warning "Environnement conservé (--quick activé)"
        echo "Pour nettoyer : docker compose -f docker-compose.dev.yml down -v"
    fi
else
    print_error "Échec du démarrage de l'environnement"
    cat /tmp/docker-compose-up.log | tail -20
fi

# Résumé des tests
print_header "Résumé des tests"

TOTAL_TESTS=$((PASSED_TESTS + FAILED_TESTS))
echo -e "\nTests réussis: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Tests échoués: ${RED}$FAILED_TESTS${NC}"
echo -e "Total: $TOTAL_TESTS"

if [ "$FAILED_TESTS" -eq 0 ]; then
    echo -e "\n${GREEN}✓ Tous les tests sont passés !${NC}\n"
    exit 0
else
    echo -e "\n${RED}✗ Certains tests ont échoué${NC}\n"
    exit 1
fi

