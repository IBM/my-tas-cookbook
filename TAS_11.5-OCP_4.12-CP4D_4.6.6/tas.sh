#!/usr/bin/bash
#set -e
## Ensure env is initialized
## Check.
source $(dirname $(realpath ${0}))/env.sh
if [[ -z "$IBM_ENTITLEMENT_KEY" ]] ; then
  echo "IBM container software's entitlement key must be defined in the env.sh file."
  exit
fi
echo "Creating new OpenShift project for Tririga Application Suite (TAS)."
oc new-project ibm-tas >> /dev/null 2>&1
echo "Creating TAS operator. Ignore the temporary NotFound error."
oc create -f ${PROJECT_DIR}/manifests/tas/tasopr.yaml >> /dev/null 2>&1
sleep 1
echo "Creating operator subscription for TAS."
oc create -f ${PROJECT_DIR}/manifests/tas/tassubs.yaml >> /dev/null 2>&1
while [ "$TASSVC" != "Succeeded" ]; do TASSVC=$(oc get csv ibm-tririga.v11.5.0 -o jsonpath='{.status.phase}{"\n"}'); echo "Installing Tririga Operator..." $TASSVC; sleep 10; done
echo "Creating secret object with entitlement software key."
oc create secret docker-registry ibm-entitlement --docker-server=cp.icr.io --docker-username=cp --docker-password=${IBM_ENTITLEMENT_KEY} -n ibm-tas >> /dev/null 2>&1
echo "Exporting DB2 Warehouse SSL certificate as a variable."
export DB2W_CA_CERT=$(oc get secret -n ibm-cpd internal-tls -o jsonpath='{.data.ca\.crt}' | base64 -d) >> /dev/null 2>&1
echo "Populating DB2W SSL certificate as a YAML file."
echo "$DB2W_CA_CERT" | sed 's/^/     /' >> ${PROJECT_DIR}/manifests/tas/tasdbsec.yaml
echo "Creating secret object with DB2W certificate."
oc create -f ${PROJECT_DIR}/manifests/tas/tasdbsec.yaml >> /dev/null 2>&1
echo "ca.crt: |" | sed 's/^/  /' >> ${PROJECT_DIR}/manifests/tas/tasslssec.yaml
export SLS_CA=$(oc get secret -n ibm-sls sls-cert-client -o jsonpath='{.data.ca\.crt}' | base64 -d)
echo "$SLS_CA" | sed 's/^/    /' >> ${PROJECT_DIR}/manifests/tas/tasslssec.yaml
echo "tls.crt: |" | sed 's/^/  /' >> ${PROJECT_DIR}/manifests/tas/tasslssec.yaml
export SLS_TLS=$(oc get secret -n ibm-sls sls-cert-client -o jsonpath='{.data.tls\.crt}' | base64 -d)
echo "$SLS_TLS" | sed 's/^/    /' >> ${PROJECT_DIR}/manifests/tas/tasslssec.yaml
echo "tls.key: |" | sed 's/^/  /' >> ${PROJECT_DIR}/manifests/tas/tasslssec.yaml
export SLS_KEY=$(oc get secret -n ibm-sls sls-cert-client -o jsonpath='{.data.tls\.key}' | base64 -d)
echo "$SLS_KEY" | sed 's/^/    /' >> ${PROJECT_DIR}/manifests/tas/tasslssec.yaml
echo "Creating secret object with certificate for Suite License Service."
oc create -f ${PROJECT_DIR}/manifests/tas/tasslssec.yaml >> /dev/null 2>&1
export UDS_CRT=$(oc get secret -n ibm-common-services event-api-certs -o jsonpath='{.data.tls\.crt}' | base64 -d)
echo "$UDS_CRT" | sed 's/^/    /' >> ${PROJECT_DIR}/manifests/tas/tasudssec.yaml
export UDSAPIKEY=$(oc get secret uds-api-key -n ibm-common-services --output="jsonpath={.data.apikey}" | base64 -d)
echo "Creating secret object with certificate for User Data Service."
envsubst < ${PROJECT_DIR}/manifests/tas/tasudssec.yaml | oc create -f - >> /dev/null 2>&1
echo "Installing Tririga Applicaion Suite. This will take several hours!"
envsubst < ${PROJECT_DIR}/manifests/tas/tascr.yaml | oc create -f - >> /dev/null 2>&1
while [ "$TASCR" != "TRIRIGA Application Suite is ready." ]; do TASCR=$(oc get Tririga my-tririga -o jsonpath='{.status.conditions[0].message}{"\n"}'); echo "Wait 2+ hours!..." $TASCR; sleep 40; done
host=$(oc get route -n ibm-tas my-tririga | grep tririga | awk '{print $2}')
context=$(oc get route -n ibm-tas my-tririga | grep tririga | awk '{print $3}')
echo "TRIRIGA URL"
echo https://$host$context/index.html
export TASPSW=$(oc get secret my-tririga-tas-system-user -n ibm-tas --output="jsonpath={.data.psw}" | base64 -d); echo "Username: system, Password:" $TASPSW
echo "TRIRIGA Admin Console URL"
echo https://$host$context/html/en/default/admin