#!/usr/bin/bash
# set -e
cat <<EOF | oc create -f -
---
apiVersion: v1
kind: Namespace
metadata:
  name: db2u
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
        storageClassName: managed-nfs-storage
    - name: data
      type: template
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 100Gi
        storageClassName: managed-nfs-storage
    - name: backup
      type: create
      spec:
        accessModes:
          - ReadWriteMany
        resources:
          requests:
            storage: 100Gi
        storageClassName: managed-nfs-storage
    - name: tempts
      type: template
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 10Gi
        storageClassName: managed-nfs-storage
    - name: archivelogs
      type: create
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 25Gi
        storageClassName: managed-nfs-storage
  size: 1
EOF
DB2UCLUSTER=$(oc get Db2uCluster db2ucluster -o jsonpath='{.status.state}{"\n"}')
while [ "$DB2UCLUSTER" != "Ready" ]; do DB2UCLUSTER=$(oc get Db2uCluster db2ucluster -o jsonpath='{.status.state}{"\n"}'); echo "Installing DB2..." $DB2UCLUSTER; sleep 20; done