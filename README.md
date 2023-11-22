# my-tas-cookbook

Implementation/deployment steps for Tririga Application Suite using DB2 Warehouse on Cloud Pak for Data. TAS 11.5 based on [official documentation](https://www.ibm.com/docs/en/tas/11.5) using Bash automation created by [Arif Ali](https://www.linkedin.com/in/arifsali/) (acknowledgement: Sumit Puri).

## Git clone

```shell
git clone -b TAS_11.5-OCP_4.12-CP4D_4.6.6 --single-branch https://github.com/IBM/my-tas-cookbook.git ; cd my-tas-cookbook/TAS_11.5-OCP_4.12-CP4D_4.6.6/
```
sed -i -e 's/\r$//' db2createdb.sh
📌 Place your AppPoint license file (license.dat) at the root of the folder.

## Cloud Pak for Data 4.6.6

📌 Open `env.sh` file and carefully update all values based on the provided instructions. This includes inserting your container software's entitlement key, your AppPoint license file's Host ID number, and storage selection based on the type of OpenShift cluster you have provisioned.

```shell
export PATH=$HOME/my-tas-cookbook/TAS_11.5-OCP_SNO_4.12-DB2/cpd-cli:$PATH ; wget https://github.com/IBM/cpd-cli/releases/download/v12.0.6/cpd-cli-linux-EE-12.0.6.tgz ; tar xvf cpd-cli-linux-EE-12.0.6.tgz ; mv cpd-cli-linux-EE-12.0.6-63/ cpd-cli
```
```
oc login ... 
```
```
cpd-cli manage oc login ...
```
```shell
source env.sh; cpd-cli manage add-icr-cred-to-global-pull-secret ${IBM_ENTITLEMENT_KEY}
```
```shell
./cpd.sh
```
⏰ 1.5 hours.

## DB2 External

1. TBA

db2ldap=$(oc get po | grep c-db2ucluster-ldap- | awk {'print $1'}) ; echo $db2ldap
oc rsh ${db2ldap} /opt/ibm/ldap_scripts/addLdapUser.py -u tridata -p tridata -r admin
sed -i 's/\r$//' db2createdb.sh
oc cp db2configinst.sh c-db2ucluster-db2u-0:/tmp
oc cp db2createdb.sh c-db2ucluster-db2u-0:/tmp
oc cp create-ts.sql c-db2ucluster-db2u-0:/tmp
oc cp ssl-setup.sh c-db2ucluster-db2u-0:/tmp
oc exec -ti c-db2ucluster-db2u-0 -- chmod 666 /tmp/db2configinst.sh
oc exec -ti c-db2ucluster-db2u-0 -- chmod 666 /tmp/db2createdb.sh
oc exec -ti c-db2ucluster-db2u-0 -- su - db2inst1 -c "sh /tmp/db2configinst.sh db2inst1 50000 /mnt/blumeta0/home/db2inst1/sqllib"
#./db2configinst.sh db2inst1 50001 /mnt/blumeta0/home/db2inst1/sqllib
oc exec -ti c-db2ucluster-db2u-0 -- su - db2inst1 -c "sh /tmp/db2createdb.sh tasdb db2inst1 US /mnt/blumeta0/home/db2inst1/sqllib tridata"
oc exec -ti c-db2ucluster-db2u-0 -- su - db2inst1
    export DB_SCHEMA=db2inst1
    export DB_USERNAME=tridata
    db2 connect to TASDB
    cp /tmp/create-ts.sql .
    db2 -tvf create-ts.sql
db2 connect to tasdb user tridata using tridata
oc exec -ti c-db2ucluster-db2u-0 -- su - db2inst1 -c "sh /tmp/ssl-setup.sh db2inst1"
db2 connect to tasdb user tridata using tridata



<details>
<summary> 

### ⚙ Expand to read more ... 

</summary>

2. TBA

</details>


8. Run `./db2wh.sh` ⏰: 45 minutes

## TAS dependencies

9. Run `./dependencies.sh` ⏰: 45 minutes

## TAS

10. Run `./tas.sh` ⏰ 2-3 hours.

## Log in

11. Use URL ending in `/tririga/index.html` Username: `system` / Password is in secret: my-tririga-tas-system-user
