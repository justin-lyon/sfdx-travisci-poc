#!/bin/bash

get_last_success_commit () {

  REPO_FULL_NAME=$1
  BRANCH_NAME=$2
  JOB_TYPE=$3
  PATTERN=${4:-$2}

  declare -r BB_API="https://api.bitbucket.org/2.0/repositories/$REPO_FULL_NAME"
  declare -r PIPELINES_URI="/pipelines/"
  declare -r QUERY_PARAMS='?page=1&pagelen=100&sort=-created_on'

  # curl -u $USERNAME:$PASSWORD "$BB_API$PIPELINES_URI$QUERY_PARAMS" \
    | jq '[ .values[] | { uuid: .uuid, state: .state, target: .target} ]' \
    | jq --arg JOB_TYPE "$JOB_TYPE" '[ .[] | select( .target.selector.type == $JOB_TYPE ) ]' \
    | jq --arg PATTERN "$PATTERN" '[ .[] | select( .target.selector.pattern == $PATTERN ) ]' \
    | jq --arg BRANCH "$BRANCH_NAME" '[ .[] | select( .target.ref_name == $BRANCH ) ]' \
    | jq '[ .[] | select( .state.name == "COMPLETED" ) ]' \
    | jq '[ .[] | select( .state.result.name == "SUCCESSFUL" ) ]' \
    | jq -r '.[0].target.commit.hash'
    # | jq '[ .values[] | { uuid: .uuid, state: .state.name, result: .state.result.name, branch: .target.ref_name, commit: .target.commit.hash, selector: .target.selector } ]' \
    # | jq --arg JOB_TYPE "$JOB_TYPE" '[ .[] | select( .selector.type == $JOB_TYPE ) ]' \
    # | jq --arg PATTERN "$PATTERN" '[ .[] | select( .selector.pattern == $PATTERN ) ]' \
    # | jq --arg BRANCH "$BRANCH_NAME" '[ .[] | select( .branch == $BRANCH ) ]' \
    # | jq '[ .[] | select( .state == "COMPLETED" ) ]' \
    # | jq '[ .[] | select( .result == "SUCCESSFUL" ) ]' \
}
