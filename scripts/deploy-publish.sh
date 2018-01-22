#!/bin/sh

#
# Deploys the public directory of the project to Amazon S3.
#
# Arguments until the end of options (identified by "--") are appended to the
# `aws s3 sync` command line.
# 
# Arguments after that are executed as command, which inherits the exported
# variables.
#
# Requires environment variables set by `deploy-env.sh`.
#
# Usage: ./deploy-env.sh -- ./deploy-public.sh [args...] [-- command args...]
#

# Calls a given function with arguments until the index defined by $INDEX:
callback_with_options() {
  # The first argument is the callback function to execute:
  CALLBACK=$1; shift
  # Only keep arguments in front of the given index:
  eval "set -- $([ "$INDEX" != 0 ] && printf '"$%s" ' $(seq "$INDEX"))"
  # Execute the callback function with the sliced set of arguments:
  "$CALLBACK" "$@"
}

# Syncs the puplic files to S3 (excluding hidden files):
sync() {
  aws-vault exec "$ROLE" -- \
    aws s3 sync public/ "s3://$BUCKET/$PROJECT/$STAGE/" \
      --exclude '.*' \
      --exclude '*/.*' \
      "$@"
}

# Exit immediately if a command exits with a non-zero status:
set -e

# Store the current working directory:
CWD="$PWD"
# Enter the project directory:
cd "$(dirname "$0")/.."

# Apply git commit timestamps to the files in the public directory:
./bin/apply-commit-times.sh public/

# Calculate the end of options index (identified by "--"): 
INDEX=-1;N=0; for ARG; do [ "$ARG" = -- ] && INDEX=$N && break; N=$((N+1)); done

if [ "$INDEX" != -1 ]; then
  # Execute the sync command with the option arguments:
  callback_with_options sync "$@"
  # Restore the working directory:
  cd "$CWD"
  # Remove arguments until and including the end of options identifier:
  shift "$((INDEX+1))"
  # Execute the remaining arguments as command line:
  exec "$@"
else
  sync "$@"
fi
