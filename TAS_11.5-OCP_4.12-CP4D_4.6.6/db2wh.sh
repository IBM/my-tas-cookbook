#!/usr/bin/bash
set -e
## Run from a specific line: bash <(sed -n '59,$p' db2wh.sh)
source $(dirname $(realpath ${0}))/env.sh
git clone https://github.com/IBM/tas-db-prep.git
cd tas-db-prep/cp4d-db2wh
chmod +x *.sh
oc project ibm-cpd
sh prepareDB.sh c-db2wh-${DB2W_INSTANCE_ID}-db2u-0 TASDB tridata SMALL