#!/bin/bash

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

# Environment Variables
# Set these variables at https://travis-ci.org/gordon-cs/gordon-360-ui/settings
# HOSTNAME hostname for sending files to
#   Normally 360react.gordon.edu
# DEPLOY_USER username to log into server
# DEPLOY_PASSWORD password to log into server
# PRODUCTION_DIR absolute path to directory for production app
# STAGING_DIR absolute path to directory for staging app
#   Both are normally under D:\wwwroot

# Variable used to create web.config
# Note: Regular expression replaces all quotes with two quotes, i.e. " => "" (for PowerShell)
WEB_CONFIG=`sed -e 's/\"/\"\"/g' web_config`

# Get current environment (production or staging) from argument passed by Travis
DEPLOY_ENV="$1"

# Decide which directory to deploy to based on deploy environment
if [ "$DEPLOY_ENV" = "production" ]; then
  DIR="$PRODUCTION_DIR"
else
  DIR="$STAGING_DIR"
fi

BUILD_DIR="build"
# Gets and formats the date for the backup file
# Note that the time is in GMT, so is 4-5 hours ahead of local time
CURRDATE=`date +"%m-%d-%Y-%H-%M"`


# TODO: add code to delete backups over some age (1 month?)
printf "%s\n" "WARNING: NOT removing backup directory from previous deployment..."

# NOTE: this doesn't work since backups are now named with the a timestamp

# Remove temporary directory (using PowerShell commands, not Bash commands)
# sshpass -p "$DEPLOY_PASSWORD" ssh "$DEPLOY_USER"@"$HOSTNAME" \
#  "if (Test-Path "$DIR-backup") { rm -r "$DIR-backup"; }"

#if [ $? == 0 ]; then
#  printf "%s\n" "Successfully removed backup directory"
#else
#  printf "%s\n" "Failed to remove backup directory"
#fi


printf "%s\n" "Moving app to backup directory... "

# Move app to temporary directory
sshpass -p "$DEPLOY_PASSWORD" ssh "$DEPLOY_USER"@"$HOSTNAME" cp -r "$DIR" "$DIR-backup-$CURRDATE"

if [ $? == 0 ]; then
  printf "%s\n" "Successfully moved app to backup directory"
else
  printf "%s\n" "Failed to move app to backup directory"
fi

printf "%s\n" "Clearing out app directory... "

# Clear out app directory
sshpass -p "$DEPLOY_PASSWORD" ssh "$DEPLOY_USER"@"$HOSTNAME" rm -r "$DIR/*"

if [ $? == 0 ]; then
  printf "%s\n" "Sucessfully cleared out app directory"
else
  printf "%s\n" "Failed to clear out app directory"
fi

printf "%s\n" "Copying app to server... "

# Copy built app (in build) to server (without build in the path)
cd build
echo sshpass -p ... scp -r . "$DEPLOY_USER"@"$HOSTNAME":"$DIR"
sshpass -p "$DEPLOY_PASSWORD" scp -r . "$DEPLOY_USER"@"$HOSTNAME":"$DIR"



# Create web.config on the server
printf "%s\n" "Creating web.config..."

sshpass -p "$DEPLOY_PASSWORD" ssh "$DEPLOY_USER"@"$HOSTNAME" \
  "echo \"$WEB_CONFIG\" | Out-File -filepath $DIR/web.config"

printf "%s\n" "Created web.config"

if [ $? == 0 ]; then
  printf "%s\n" "Successfully copied app to $DEPLOY_ENV"
else
  printf "%s\n" "Failed to copy app to server"
fi
