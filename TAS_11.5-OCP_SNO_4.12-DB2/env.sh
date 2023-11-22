#!/usr/bin/bash
## CP4D Function
## 
# ------------------------------------------------------------------------------
# Common
# Instructions: Insert your Entitlement key from 
# https://myibm.ibm.com/products-services/containerlibrary
# Update project directory based on extracted deployment script folder.
# ------------------------------------------------------------------------------
export PROJECT_DIR="$HOME/my-tas-cookbook/TAS_11.5-OCP_SNO_4.12-DB2"
export IBM_ENTITLEMENT_KEY=
export HOSTID=
# ------------------------------------------------------------------------------
export MONGO_PASSWORD=Passw0rdPassw0rd
# ------------------------------------------------------------------------------
export TAS_SIZE=small
# ------------------------------------------------------------------------------
# TAS Storage - File
# Instructions: Change this based on OpenShift's StorageClass
# ------------------------------------------------------------------------------
export FILE_STORAGE=managed-nfs-storage
# export FILE_STORAGE=ocs-storagecluster-cephfs
# export FILE_STORAGE=ibmc-file-gold-gid
# ------------------------------------------------------------------------------
# TAS Storage - Block
# Instructions: Change this based on OpenShift's StorageClass
# ------------------------------------------------------------------------------
## Block storage
export BLOCK_STORAGE=managed-nfs-storage
export UDS_STORAGE_CLASS=managed-nfs-storage
# export BLOCK_STORAGE=ocs-storagecluster-ceph-rbd
# export UDS_STORAGE_CLASS=ocs-storagecluster-ceph-rbd
# export BLOCK_STORAGE=ibmc-block-gold
# export UDS_STORAGE_CLASS=ibmc-block-bronze