#!/bin/bash

# Import utilities
. ./scripts/lib/utilities.sh

# Print SFDX Info
get_info () {
  echo "*** Print SFDX Info"
  sfdx --version
  sfdx plugins --core
  sfdx force:org:list
}

# Login to a Sandbox by JWT
jwt_login () {
  echo "*** Logging in to $4 as $3 at $5."
  sfdx force:auth:jwt:grant -d \
    --clientid $1 \
    --jwtkeyfile $2 \
    --username $3 \
    -a $4 \
    --instanceurl $5
}

# Login to any Org by Web
web_login () {
  HUB_ALIAS=${1:-"DevHub"}
  sfdx force:auth:web:login -d -a $HUB_ALIAS
}

# Delete a Scratch Org
delete_org () {
  echo "*** Removing old scratch org, $1"
  sfdx force:org:delete -p -u $1
}

# Create a new Scratch Org
create_org () {
  DURATION=${2:-10}
  echo "*** Creating scratch Org. Alias: $1, for $DURATION days."
  sfdx force:org:create -s -a "$1" -d $DURATION -f "$3"
}

# Push local to a Scratch Org.
source_push () {
  echo "*** Pushing metadata to $1"
  sfdx force:source:push -u $1
}

# Pull changes from a Scratch Org.
source_pull () {
  echo "*** Pulling changes from $1"
  sfdx force:source:pull -u $1
}

# Import Data to scratch org
# Requires data path $2=data/my-plan.json
data_import () {
  echo "*** Creating data from $2 to $1"
  sfdx force:data:tree:import -u $1 -p $2
}

# Assign one Permission Set
assign_permset () {
  echo "*** Assigning $2 Permission Set in $1"
  sfdx force:user:permset:assign -u $1 -n $2
}

# Usage: $ bulk_assign_permsets $ORG_ALIAS $PERMSET_ONE $PERMSET_TWO $PERMSET_ETC
# ALT Usage: $ bulk_assign_permsets $1 ${@:2}
bulk_assign_permsets () {
  for i in "${@:2}"
  do
    assign_permset $1 $i
  done
}

# Convert SFDX src format to classic Metadata Format
convert_mdtapi () {
  SRC_ROOT=${1:-force-app/main}
  OUTPUT_ROOT=${2:-mdtapi}
  PKG_NAME=${3:-unpackaged}

  echo "*** Converting src in $SRC_ROOT to metadata format in $OUTPUT_ROOT/$PKG_NAME"
  sfdx force:source:convert \
    -r $SRC_ROOT \
    -d $OUTPUT_ROOT/$PKG_NAME
}

# Deploy to $TARGET_ORG_ALIAS, (opt) --checkonly to Validate only.
deploy_mdtapi () {
  disable_error_trapping

  TARGET_ORG_ALIAS=$1
  OUTPUT_ROOT=${2:-mdtapi}
  PKG_NAME=${3:-unpackaged}

  echo "*** Deploying with Local Tests to $TARGET_ORG_ALIAS."
  sfdx force:mdapi:deploy -d $OUTPUT_ROOT/$PKG_NAME \
    -u $TARGET_ORG_ALIAS \
    --wait 5 \
    --testlevel RunLocalTests \
    ${@:4}

  handle_error $RETURN_CODE
}

# Requires
#  /manifest/destructiveChanges.xml
#    Describes the explicit components to delete
#  /manifest/package.xml
#    Empty except for the api version.
# See /_manifest/README.md for details
destructive_mdtapi () {
  disable_error_trapping

  TARGET_ORG_ALIAS=$1

  echo "*** Deploying Destructive Changes with Local Tests to $TARGET_ORG_ALIAS."
  sfdx force:mdapi:deploy -d manifest \
    -u $TARGET_ORG_ALIAS \
    --wait 5 \
    --testlevel RunLocalTests \
    ${@:2}
    # Optional, pass the --checkonly flag to validate only.
    # ex: destructive_mdtapi $ALIAS --checkonly

  handle_error $RETURN_CODE
}

# Run All Local Tests in Scratch Org
run_local_tests () {
  disable_error_trapping

  echo "*** Running All Local Apex Tests..."
  sfdx force:apex:test:run -c \
    -r human \
    -l RunLocalTests \
    -u $1

  handle_error $RETURN_CODE
}
