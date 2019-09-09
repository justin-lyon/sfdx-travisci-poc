#!/bin/bash
# Usage: sh scripts/create-org.sh

# Import defaults
. ./scripts/lib/defaults.sh

# Import functions
. ./scripts/lib/sfdx.sh

# Main script starts here
SCRATCH_ORG_NAME="${1:-validation}"
echo "*** Validating $BITBUCKET_BRANCH to $SCRATCH_ORG_NAME"
create_org $SCRATCH_ORG_NAME 1 $SCRATCH_DEF_PATH
source_push $SCRATCH_ORG_NAME
run_local_tests $SCRATCH_ORG_NAME
delete_org $SCRATCH_ORG_NAME
