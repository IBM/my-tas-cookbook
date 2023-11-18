#!/usr/bin/bash
# set -e
## e.g.: To run from a specific line: bash <(sed -n '9,$p' cpd.sh)
source $(dirname $(realpath ${0}))/env.sh
#ibmcloud oc worker reload -q -f -c ${CLUSTER_NAME} ${WORKER_LIST}
cpd-cli manage apply-olm --release=${VERSION} --components=${COMPONENTS} --cpd_operator_ns=${PROJECT_CPD_OPS}
cpd-cli manage setup-instance-ns --cpd_instance_ns=${PROJECT_CPD_INSTANCE} --cpd_operator_ns=${PROJECT_CPD_OPS}
cpd-cli manage apply-cr --components=${COMPONENTS} --release=${VERSION} --cpd_instance_ns=${PROJECT_CPD_INSTANCE} --block_storage_class=${STG_CLASS_BLOCK} --file_storage_class=${STG_CLASS_FILE} --license_acceptance=true
cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INSTANCE}
oc project ${PROJECT_CPD_INSTANCE} ; oc delete route cpd
oc extract secret/ibm-nginx-internal-tls-ca --keys=cert.crt --to=- > ./cert.crt
oc create route reencrypt cpd --service=ibm-nginx-svc --port=ibm-nginx-https-port --dest-ca-cert=./cert.crt
cpd-cli manage oc annotate route cpd -n ibm-cpd --overwrite haproxy.router.openshift.io/timeout=360s
cpd-cli manage get-cpd-instance-details --cpd_instance_ns=${PROJECT_CPD_INSTANCE} --get_admin_initial_credentials=true