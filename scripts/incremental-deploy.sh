#!/bin/bash

. ./scripts/lib/bitbucket.sh
. ./scripts/lib/git.sh
. ./scripts/lib/utilities.sh
. ./scripts/lib/sfdx.sh

REPO_FULL_NAME=$1
ALIAS=$2
BRANCH_NAME=$3
JOB_TYPE=$4
DEPLOY_ARGS=${@:5}

LOG_DIR="logs"
LOG_FILE="$LOG_DIR/git-diff.log"
INCREMENTAL_DIR="incremental"
SRC_ROOT="$INCREMENTAL_DIR/force-app"
MDT_ROOT="mdtapi"
PACKAGE_NAME="unpackaged"

mkdir -p $LOG_DIR $INCREMENTAL_DIR
touch $LOG_FILE

echo "*** Getting commit hash for last successful job, $JOB_TYPE:$BRANCH_NAME"
COMMIT_HASH=$(get_last_success_commit $REPO_FULL_NAME $BRANCH_NAME $JOB_TYPE)

echo "*** Get diff between $COMMIT_HASH and $BRANCH_NAME HEAD"
diff_commit_to_head $BRANCH_NAME $COMMIT_HASH $LOG_FILE

echo "*** Compile incremental changes from diff"
build_incremental_dir $LOG_FILE $INCREMENTAL_DIR

echo "*** Convert incremental to metadata api and deploy"

convert_mdtapi $SRC_ROOT $MDT_ROOT $PACKAGE_NAME
deploy_mdtapi $ALIAS $MDT_ROOT $PACKAGE_NAME $DEPLOY_ARGS

echo "*** Cleaning up rm $INCREMENTAL_DIR and $MDT_ROOT"
rm -rf $INCREMENTAL_DIR
rm -rf $MDT_ROOT
