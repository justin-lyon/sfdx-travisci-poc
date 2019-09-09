#!/bin/bash
# Usage: sh scripts/jwt-hub-login.sh

# Import functions
. ./scripts/lib/sfdx.sh

jwt_login $1 $2 $3 $4 $5
get_info
