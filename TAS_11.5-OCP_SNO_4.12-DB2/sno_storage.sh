#!/bin/bash
set -e
oc new-project nfsprovisioner-operator
cat << EOF | oc apply -f -  
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: nfs-provisioner-operator
  namespace: openshift-operators
spec:
  channel: alpha
  installPlanApproval: Automatic
  name: nfs-provisioner-operator
  source: community-operators
  sourceNamespace: openshift-marketplace
EOF
until oc api-resources --api-group=cache.jhouse.com | grep jhouse.com &> /dev/null; do  echo "Operator installation in progress...";  sleep 5; done
export target_node=$(oc get node --no-headers -o name|cut -d'/' -f2)
oc label node/${target_node} app=nfs-provisioner
oc debug node/${target_node} << EOF
chroot /host
mkdir -p /home/core/nfs
chcon -Rvt svirt_sandbox_file_t /home/core/nfs
exit
exit
EOF
cat << EOF | oc apply -f -
apiVersion: cache.jhouse.com/v1alpha1
kind: NFSProvisioner
metadata:
  name: nfsprovisioner-sample
  namespace: nfsprovisioner-operator
spec:
  nfsImageConfiguration:
    image: 'k8s.gcr.io/sig-storage/nfs-provisioner:v3.0.1'
    imagePullPolicy: IfNotPresent
  scForNFS: managed-nfs-storage
  hostPathDir: /home/core/nfs
EOF
sleep 1m
oc patch storageclass managed-nfs-storage -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'