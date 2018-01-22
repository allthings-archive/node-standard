#!/bin/sh

#
# Deploys the the project to AWS
#
# Usage: ./deploy.sh
#

set -e

cd "$(dirname "$0")/.."

# Source the deployment configuration:
# shellcheck disable=SC1091
. ./bin/deploy-env.sh --

log() {
  background=$(tput setab 1)
  bold=$(tput bold)
  normal=$(tput sgr0)
  white=$(tput setaf 7)
  uncolor='\033[0m'

  echo "${background}${bold}  --- ${white}${1} ---  ${uncolor}${normal}"
}

# Iterate over the dependency requirements:
while IFS= read -r REQUIREMENT; do
  # Skip empty lines and lines starting with a hash (#):
  [ -z "$REQUIREMENT" ] || [ "${REQUIREMENT#\#}" != "$REQUIREMENT" ] && continue
  if ! command -v "$REQUIREMENT" > /dev/null 2>&1; then
    echo "\"$REQUIREMENT\" is not available in PATH" >&2
    echo "Please install \"$REQUIREMENT\" (or try yarn install)" >&2
    exit 1
  fi
done << EOL
aws
aws-vault
serverless
EOL

log "Check integrity. Run 'yarn' if it fails"
yarn check --integrity --production=false

log "Deploying $PROJECT to $STAGE"

log "Cleaning up workspace"
yarn run clean

log "Building assets"
yarn build

log "Deploying static assets to AWS S3"
./bin/deploy-public.sh \
  --exclude 'static/js/prod/*'

./bin/deploy-public.sh \
  --exclude '*' \
  --include 'static/js/prod/*' \
  --cache-control 'public,max-age=31536000,immutable'

log "Deploying server side rendering Lambda/API Gateway service"
aws-vault exec allthings-deploy -- serverless deploy -v
