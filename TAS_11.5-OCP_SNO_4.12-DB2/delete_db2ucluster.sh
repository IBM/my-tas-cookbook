#!/usr/bin/bash
#set -e
## Delete DB2
oc delete Formation db2ucluster -n db2u >> /dev/null 2>&1
echo "Formation deleted"
oc delete Db2uCluster db2ucluster -n db2u >> /dev/null 2>&1
echo "Db2uCluster deleted. Wait."
sleep 1m
oc delete Subscription -n ibm-common-services ibm-db2u-operator >> /dev/null 2>&1
echo "Subscription deleted."
oc delete csv db2u-operator.v110508.0.3 -n ibm-common-services >> /dev/null 2>&1
oc delete NamespaceScope db2u -n ibm-common-services >> /dev/null 2>&1
echo "Wait."
sleep 1m
oc delete Namespace db2u >> /dev/null 2>&1
oc project ibm-common-services >> /dev/null 2>&1
echo "Deleted DB2. You are now in the following project."
oc project -q