#!/usr/bin/bash
# set -e
export BLOCKSTORAGE=ocs-storagecluster-ceph-rbd
export FILESTORAGE=ocs-storagecluster-cephfs
export DATASIZE=500Gi
cat <<EOF | oc create -f -
---
apiVersion: v1
kind: Namespace
metadata:
  name: db2u
EOF
while [ "$NAMESPACE" != "Active" ]; do NAMESPACE=$(oc get Namespace db2u -n db2u -o jsonpath='{.status.phase}{"\n"}'); echo "Installing Namespace..." $NAMESPACE; sleep 5; done
cat <<EOF | oc create -f -
---
apiVersion: operator.ibm.com/v1
kind: NamespaceScope
metadata:
  name: db2u
  namespace: ibm-common-services
spec:
  csvInjector:
    enable: false
  namespaceMembers:
    - db2u
    - ibm-common-services
EOF
while [ "$NAMESPACESCOPE" != '["db2u","ibm-common-services"]' ]; do NAMESPACESCOPE=$(oc get NamespaceScope db2u -n ibm-common-services -o jsonpath='{.status.validatedMembers}{"\n"}'); echo "Installing NamespaceScope...Ignore NotFound errors." $NAMESPACESCOPE; sleep 5; done
cat <<EOF | oc create -f -
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-db2u-operator
  namespace: ibm-common-services
spec:
  channel: v110508.0
  installPlanApproval: Automatic
  name: db2u-operator
  source: ibm-operator-catalog
  sourceNamespace: openshift-marketplace
EOF
while [ "$(oc get csv db2u-operator.v110508.0.3 -n ibm-common-services -o jsonpath='{ .status.phase } : { .status.message}')" != "Succeeded : install strategy completed with no errors" ]; do sleep 5; echo "Waiting for IBM DB2 Operator to be created."; done
cat <<EOF | oc create -f -
apiVersion: db2u.databases.ibm.com/v1
kind: Db2uCluster
metadata:
  name: db2ucluster
  namespace: db2u
spec:
  license:
    accept: true
  account:
    privileged: true
  environment:
    dbType: db2oltp
    database:
      name: bludb
    ldap:
      enabled: true
  version: s11.5.8.0-cn3
  storage:
    - name: meta
      type: create
      spec:
        accessModes:
          - ReadWriteMany
        resources:
          requests:
            storage: 50Gi
        storageClassName: ${FILESTORAGE}
    - name: data
      type: template
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: ${DATASIZE}
        storageClassName: ${BLOCKSTORAGE}
    - name: backup
      type: create
      spec:
        accessModes:
          - ReadWriteMany
        resources:
          requests:
            storage: 100Gi
        storageClassName: ${FILESTORAGE}
    - name: tempts
      type: template
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 10Gi
        storageClassName: ${BLOCKSTORAGE}
    - name: archivelogs
      type: create
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 25Gi
        storageClassName: ${BLOCKSTORAGE}
  size: 1
EOF
while [ "$DB2UFORMATION" != "OK" ]; do DB2UFORMATION=$(oc get Formation db2ucluster -n db2u -o jsonpath='{.status.state}{"\n"}'); echo "Installing DB2...It will take a few minutes. Ignore NotFound errors." $DB2UFORMATION; sleep 40; done
while [ "$DB2UCLUSTER" != "Ready" ]; do DB2UCLUSTER=$(oc get Db2uCluster db2ucluster -n db2u -o jsonpath='{.status.state}{"\n"}'); echo "DB2uCluster..." $DB2UCLUSTER; sleep 5; done
export DB2INSTPWD=$(oc get secret c-db2ucluster-instancepassword -n db2u --output="jsonpath={.data.password}" | base64 -d)
echo "-----------"
echo "Your DB2 Instance password is: $DB2INSTPWD"
echo "-----------"
echo -e "Log in to the container using this command:\n  oc exec -ti c-db2ucluster-db2u-0 -n db2u -- su - db2inst1\n"
echo -e "Connect to the database using this command:\n  db2 connect to BLUDB user db2inst1 using <password>\n"
echo "Type exit to come out of the container."
echo "-----------"