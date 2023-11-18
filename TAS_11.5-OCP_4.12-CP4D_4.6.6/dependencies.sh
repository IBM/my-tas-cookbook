#!/bin/bash
###!/usr/bin/bash
## Run from a specific line: source env.sh ; bash <(sed -n '39,$p' dependencies.sh)
## Check license file.
FILE=./license.dat
if [[ ! -f "$FILE" ]] ; then
  echo "Place the AppPoint License file (license.dat) in this directory."
  exit
fi
set -e
## Ensure env is initialized
source $(dirname $(realpath ${0}))/env.sh
### MongoDB
echo "Installing MongoDB. Please wait!"
oc new-project mongodb >> /dev/null 2>&1
git clone https://github.com/mongodb/mongodb-kubernetes-operator.git >> /dev/null 2>&1
oc create -f mongodb-kubernetes-operator/config/crd/bases/mongodbcommunity.mongodb.com_mongodbcommunity.yaml >> /dev/null 2>&1
oc apply -k mongodb-kubernetes-operator/config/rbac/ >> /dev/null 2>&1
oc create -f ${PROJECT_DIR}/manifests/mongodb/manager.yaml >> /dev/null 2>&1
mkdir ${PROJECT_DIR}/mongo_certs ; cd $_
openssl genrsa -out ca.key 4096 >> /dev/null 2>&1
openssl req -new -x509 -days 3650 -key ca.key -reqexts v3_req -extensions v3_ca -out ca.crt -subj "/C=US/ST=NY/L=New York/O=AIAPPS/OU=TAS/CN=TAS" >> /dev/null 2>&1
oc create secret tls ca-key-pair --cert=ca.crt --key=ca.key -n mongodb >> /dev/null 2>&1
oc create configmap custom-ca --from-file=ca.crt -n mongodb >> /dev/null 2>&1
cd ..
envsubst < ${PROJECT_DIR}/manifests/mongodb/mongosec.yaml | oc create -f - >> /dev/null 2>&1
envsubst < ${PROJECT_DIR}/manifests/mongodb/mongocr.yaml | oc create -f - >> /dev/null 2>&1
MONGOSVC=$(oc get MongoDBCommunity my-mongodb -o jsonpath='{.status.phase}{"\n"}')
while [ "$MONGOSVC" != "Running" ]; do MONGOSVC=$(oc get MongoDBCommunity my-mongodb -o jsonpath='{.status.phase}{"\n"}'); echo "Installing MongoDB..." $MONGOSVC; sleep 20; done
### SLS
#### IBM Operator Catalog Source
echo "Installing IBM Suite License Service. Please wait! Ignore temporary NotFound errors."
oc create -f ${PROJECT_DIR}/manifests/catalogsource/icatsrc.yaml >> /dev/null 2>&1
echo "Waiting a few minutes ... IBM's Operator Catalog"
sleep 3m
oc new-project ibm-sls >> /dev/null 2>&1
export MONGODB_NAMESPACE=mongodb
export MONGODB_USERNAME=$(oc get secret -n $MONGODB_NAMESPACE my-mongodb-admin-admin -o jsonpath="{.data.username}" | base64 -d)
export MONGODB_PASSWORD=$(oc get secret -n $MONGODB_NAMESPACE my-user-password -o jsonpath="{.data.password}" | base64 -d)
export MONGODB_CRT=`cat ${PROJECT_DIR}/mongo_certs/ca.crt`
echo "${MONGODB_CRT}" | sed 's/^/          /' >> ${PROJECT_DIR}/manifests/sls/slscr.yaml
envsubst < ${PROJECT_DIR}/manifests/sls/slscred.yaml | oc apply -f - >> /dev/null 2>&1
oc -n ibm-sls create secret docker-registry ibm-entitlement --docker-server=cp.icr.io --docker-username=cp --docker-password=$IBM_ENTITLEMENT_KEY >> /dev/null 2>&1
oc apply -f ${PROJECT_DIR}/manifests/sls/slsopr.yaml >> /dev/null 2>&1
while \
[ "$(oc get ClusterServiceVersion ibm-sls.v3.8.1 -o jsonpath='{ .status.phase } : { .status.message}')" != "Succeeded : install strategy completed with no errors" ]; \
do sleep 5; \
echo "Waiting for Suite License Services Operator to be created."; \
done
export SLSBOOTSTRAP=`cat license.dat`
echo "$SLSBOOTSTRAP" | sed 's/^/    /' >> ${PROJECT_DIR}/manifests/sls/slsbootstrap.yaml
envsubst < ${PROJECT_DIR}/manifests/sls/slsbootstrap.yaml | oc apply -f - >> /dev/null 2>&1
# export DOMAIN=$(oc get Ingress.config cluster -o jsonpath='{.spec.domain}')
oc apply -f ${PROJECT_DIR}/manifests/sls/slscr.yaml >> /dev/null 2>&1
while \
[ "$(oc get licenseservice sls -n ibm-sls -o jsonpath='{.status.conditions[1].message}')" != "Suite License Service API is ready. GET https://sls.ibm-sls.svc/api/entitlement/config rc=200" ]; \
do sleep 45; echo "Waiting for License Service to be ready."; done
### UDS
echo "Installing IBM User Data Service."
oc project ibm-common-services >> /dev/null 2>&1
oc create secret docker-registry ibm-entitlement --docker-server=cp.icr.io --docker-username=cp --docker-password="$IBM_ENTITLEMENT_KEY" -n ibm-common-services >> /dev/null 2>&1
oc apply -f ${PROJECT_DIR}/manifests/uds/iuds.yaml >> /dev/null 2>&1
while \
[ "$(oc get csv -n ibm-common-services user-data-services-operator.v2.0.12 -o jsonpath='{ .status.phase } : { .status.message}')" != "Succeeded : install strategy completed with no errors" ]; \
do sleep 5; \
echo "Waiting for UDS Operator to be created."; \
done
oc create secret generic database-credentials -n ibm-common-services --from-literal=db_username=basuser --from-literal=db_password=admin >> /dev/null 2>&1
oc create secret generic grafana-credentials -n ibm-common-services --from-literal=grafana_username=basuser --from-literal=grafana_password=admin >> /dev/null 2>&1
envsubst < ${PROJECT_DIR}/manifests/uds/udscr.yaml | oc apply -f - >> /dev/null 2>&1
while \
[ "$(oc get AnalyticsProxy analyticsproxy -n ibm-common-services -o template --template {{.status.phase}})" != "Ready" ]; \
do sleep 45; \
echo "Waiting for AnalyticsProxy to be created. This could take 45 minutes."; \
done
oc apply -f ${PROJECT_DIR}/manifests/uds/udskey.yaml >> /dev/null 2>&1
sleep 1m
while \
[ "$(oc get GenerateKeys uds-api-key -n ibm-common-services -o template --template {{.status.phase}})" != "Ready" ]; \
do sleep 5; \
echo "Waiting for UDS API key to be created."; \
done