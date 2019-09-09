#!/bin/bash
# Usage: sh scripts/deploy-mdtapi.sh

# Import functions
. ./scripts/lib/sfdx.sh
. ./scripts/lib/utilities.sh

TARGET_ORG_ALIAS=${1:-deploy-temp}

OUTPUT_ROOT=${2:-mdtapi}
PKG_NAME=${3:-unpackaged}
SRC_ROOT=${4:-force-app/main}

convert_mdtapi $SRC_ROOT $OUTPUT_ROOT $PKG_NAME
deploy_mdtapi $TARGET_ORG_ALIAS $OUTPUT_ROOT $PKG_NAME

rm_dir $OUTPUT_ROOT
