#!/bin/bash

diff_commit_to_head () {
  BRANCH_NAME=$1
  COMMIT_HASH=$2
  LOG_FILE=${3:-logs/git-diff.log}

  git diff --name-only --diff-filter=d $COMMIT_HASH..$BRANCH_NAME > $LOG_FILE
}
