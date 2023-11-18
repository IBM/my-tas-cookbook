#!/usr/bin/bash
## CP4D Function
## 
# ------------------------------------------------------------------------------
# Common
# Instructions: Insert your Entitlement key from 
# https://myibm.ibm.com/products-services/containerlibrary
# Update project directory based on extracted deployment script folder.
# ------------------------------------------------------------------------------
export PROJECT_DIR="$HOME/my-tas-cookbook/TAS_11.5-OCP_4.12-CP4D_4.6.6"
export IBM_ENTITLEMENT_KEY=
export HOSTID=
# ------------------------------------------------------------------------------
# CP4D version
# Instructions: Do not change!
# ------------------------------------------------------------------------------
export VERSION=4.6.6
# ------------------------------------------------------------------------------
# CP4D CLI
# Instructions: Do not change!
# ------------------------------------------------------------------------------
export PATH=$HOME/my-tas-cookbook/TAS_11.5-OCP_4.12-CP4D_4.6.6/cpd-cli:$PATH
# ------------------------------------------------------------------------------
# CP4D Projects/Namespace
# Instructions: Do not change!
# ------------------------------------------------------------------------------
export PROJECT_CPFS_OPS=ibm-common-services        
export PROJECT_CPD_OPS=cpd-operators
export PROJECT_CATSRC=openshift-marketplace
export PROJECT_CPD_INSTANCE=ibm-cpd
# ------------------------------------------------------------------------------
# CP4D Components 
# More components https://www.ibm.com/docs/en/cloud-paks/cp-data/4.5.x?topic=information-determining-which-components-install
# Instructions: Do not change!
# ------------------------------------------------------------------------------
export COMPONENTS=cpfs,cpd_platform,db2wh
# ------------------------------------------------------------------------------
# CP4D Block Storage
# Instructions: Change this based on OpenShift's StorageClass
# ------------------------------------------------------------------------------
# export STG_CLASS_BLOCK=managed-nfs-storage
export STG_CLASS_BLOCK=ocs-storagecluster-ceph-rbd
# export STG_CLASS_BLOCK=ibmc-block-gold
# ------------------------------------------------------------------------------
# CP4D File Storage
# Instructions: Change this based on OpenShift's StorageClass
# ------------------------------------------------------------------------------
# export STG_CLASS_FILE=managed-nfs-storage
export STG_CLASS_FILE=ocs-storagecluster-cephfs
# export STG_CLASS_FILE=ibmc-file-gold-gid
# ------------------------------------------------------------------------------
# MongoDB
# Instructions: Supply a 15 char password, e.g, Passw0rdPassw0rd
# ------------------------------------------------------------------------------
export MONGO_PASSWORD=Passw0rdPassw0rd
# ------------------------------------------------------------------------------
# DB2W
# Instructions: You will change the this instance ID later in the process when you 
# interactively create the database instance. This instance ID is an example.
# ------------------------------------------------------------------------------
export DB2W_INSTANCE_ID=1661646324241051
# ------------------------------------------------------------------------------
# TAS Size
# Instructions: Select small/medium/large
# ------------------------------------------------------------------------------
export TAS_SIZE=small
# ------------------------------------------------------------------------------
# TAS Storage - File
# Instructions: Change this based on OpenShift's StorageClass
# ------------------------------------------------------------------------------
# export FILE_STORAGE=managed-nfs-storage
export FILE_STORAGE=ocs-storagecluster-cephfs
# export FILE_STORAGE=ibmc-file-gold-gid
# ------------------------------------------------------------------------------
# TAS Storage - Block
# Instructions: Change this based on OpenShift's StorageClass
# ------------------------------------------------------------------------------
## Block storage
# export BLOCK_STORAGE=managed-nfs-storage
# export UDS_STORAGE_CLASS=managed-nfs-storage
export BLOCK_STORAGE=ocs-storagecluster-ceph-rbd
export UDS_STORAGE_CLASS=ocs-storagecluster-ceph-rbd
# export BLOCK_STORAGE=ibmc-block-gold
# export UDS_STORAGE_CLASS=ibmc-block-bronze