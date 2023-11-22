#!/usr/bin/bash
set -e
## Run from a specific line: bash <(sed -n '59,$p' db2wh.sh)
source $(dirname $(realpath ${0}))/env.sh
git clone https://github.com/IBM/tas-db-prep.git
cd tas-db-prep/cp4d-db2wh
chmod +x *.sh
oc project db2u
DB2WHPOD=c-db2ucluster-db2u-0
sh prepareDB.sh ${DB2WHPOD} TASDB tridata SMALL