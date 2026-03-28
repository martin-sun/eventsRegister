#!/bin/bash
# ==============================================================================
# EventsRegister - Frontend Deployment to Cloudflare Pages
# ==============================================================================
# Usage:
#   ./deploy/deploy-frontend-cloudflare.sh              # Deploy to production (main)
#   ./deploy/deploy-frontend-cloudflare.sh staging       # Deploy to staging preview
#   ./deploy/deploy-frontend-cloudflare.sh production    # Deploy to production (main)
#
# Requirements:
#   - wrangler CLI installed (npm install -g wrangler)
#   - Logged in to Cloudflare (wrangler login)
#   - deploy/.env.production.frontend configured
# ==============================================================================

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_DIR="$(cd "${DEPLOY_DIR}/../frontend" && pwd)"
PROJECT_NAME="events-register"
PRODUCTION_BRANCH="main"

# Determine deploy target: staging or production
DEPLOY_TARGET="${1:-production}"
if [ "${DEPLOY_TARGET}" = "staging" ]; then
    DEPLOY_BRANCH="staging"
    DEPLOY_LABEL="Staging Preview"
elif [ "${DEPLOY_TARGET}" = "production" ]; then
    DEPLOY_BRANCH="${PRODUCTION_BRANCH}"
    DEPLOY_LABEL="Production"
else
    echo -e "${RED}Error: Unknown target '${DEPLOY_TARGET}'. Use 'staging' or 'production'.${NC}"
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  EventsRegister - Cloudflare Pages${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Project: ${GREEN}${PROJECT_NAME}${NC}"
echo -e "Target:  ${GREEN}${DEPLOY_LABEL}${NC} (branch: ${DEPLOY_BRANCH})"
echo -e "Build directory: ${GREEN}${FRONTEND_DIR}/.svelte-kit/cloudflare${NC}"
echo ""

# Check if wrangler is installed
if ! command -v wrangler &> /dev/null; then
    echo -e "${RED}Error: wrangler CLI is not installed${NC}"
    echo "Install it with: npm install -g wrangler"
    exit 1
fi

# Check if logged in to Cloudflare
echo -e "${YELLOW}Checking Cloudflare authentication...${NC}"
if ! wrangler whoami &> /dev/null; then
    echo -e "${YELLOW}Not logged in to Cloudflare. Please login:${NC}"
    wrangler login
fi

# Load environment variables
ENV_FILE="${DEPLOY_DIR}/.env.production.frontend"
if [ -f "${ENV_FILE}" ]; then
    echo -e "${GREEN}Loading environment variables from ${ENV_FILE}...${NC}"
    set -a
    source "${ENV_FILE}"
    set +a
else
    echo -e "${RED}Error: ${ENV_FILE} not found${NC}"
    echo -e "${YELLOW}Copy .env.production.frontend.example to .env.production.frontend and configure it${NC}"
    exit 1
fi

# Navigate to frontend directory
cd "${FRONTEND_DIR}"

# Install dependencies
echo ""
echo -e "${YELLOW}Installing dependencies...${NC}"
pnpm install

# Build the frontend
echo ""
echo -e "${YELLOW}Building frontend...${NC}"
pnpm run build

# Verify build output
if [ ! -d ".svelte-kit/cloudflare" ]; then
    echo -e "${RED}Error: .svelte-kit/cloudflare/ directory not found after build${NC}"
    exit 1
fi

echo -e "${GREEN}Build successful${NC}"
echo ""

# Set runtime secret for service role key
# PUBLIC_ vars are embedded at build time; the service role key must be injected at runtime.
if [ -z "${SUPABASE_SERVICE_ROLE_KEY}" ]; then
    echo -e "${RED}Error: SUPABASE_SERVICE_ROLE_KEY not set in ${ENV_FILE}${NC}"
    exit 1
fi

echo -e "${YELLOW}Setting Cloudflare Pages secret (SUPABASE_SERVICE_ROLE_KEY)...${NC}"
echo "{\"SUPABASE_SERVICE_ROLE_KEY\": \"${SUPABASE_SERVICE_ROLE_KEY}\"}" \
    | wrangler pages secret bulk --project-name="${PROJECT_NAME}"
echo -e "${GREEN}Secret set successfully${NC}"
echo ""

# Deploy to Cloudflare Pages
echo -e "${YELLOW}Deploying to Cloudflare Pages (${DEPLOY_LABEL})...${NC}"
wrangler pages deploy .svelte-kit/cloudflare --project-name="${PROJECT_NAME}" --branch="${DEPLOY_BRANCH}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Deployment Complete! (${DEPLOY_LABEL})${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
if [ "${DEPLOY_TARGET}" = "staging" ]; then
    echo -e "Preview URL: ${GREEN}https://staging.${PROJECT_NAME}.pages.dev${NC}"
    echo -e ""
    echo -e "After testing, deploy to production:"
    echo -e "  ${YELLOW}./deploy/deploy-frontend-cloudflare.sh production${NC}"
else
    echo -e "Live URL: ${GREEN}https://${PROJECT_NAME}.pages.dev${NC}"
fi
