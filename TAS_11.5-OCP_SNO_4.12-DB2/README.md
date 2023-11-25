# my-tas-cookbook

Implementation/deployment steps for Tririga Application Suite using DB2 Warehouse on Cloud Pak for Data. TAS 11.5 based on [official documentation](https://www.ibm.com/docs/en/tas/11.5) using Bash automation created by [Arif Ali](https://www.linkedin.com/in/arifsali/) (acknowledgement: Sumit Puri).

## Git clone

```shell
git clone -b TAS_11.5-OCP_SNO_4.12-DB2 --single-branch https://github.com/IBM/my-tas-cookbook.git ; cd my-tas-cookbook/TAS_11.5-OCP_SNO_4.12-DB2/
```

📌 Place your AppPoint license file (license.dat) at the root of the folder.

## Environment Variables

📌 Open `env.sh` file and carefully update all values based on the provided instructions. This includes inserting your container software's entitlement key, your AppPoint license file's Host ID number, and storage selection based on the type of OpenShift cluster you have provisioned.

## DB2u (OpenShift Operator)

<details>
<summary> 

### ⚙ Expand to read more ... 

</summary>

1. Install DB2u Operator

```
./db2ucluster.sh
```

2. Create `tridata` user account

```
oc project db2u
db2ldap=$(oc get po | grep c-db2ucluster-ldap- | awk {'print $1'}) ; echo $db2ldap
oc rsh ${db2ldap} /opt/ibm/ldap_scripts/addLdapUser.py -u tridata -p tridata -r admin
```

3. Copy scripts files over to the db2 container.

```
cd tas-db-prep/external-db2
oc project db2u
oc rsh c-db2ucluster-db2u-0 mkdir -p /tmp/scripts
for n in create-ts.sql db2configinst.sh db2createdb.sh new_db2createts.sh ssl-setup.sh; do oc cp ${n} c-db2ucluster-db2u-0:/tmp/scripts; done
oc rsh c-db2ucluster-db2u-0 ls -l /tmp/scripts
```

4. Configure DB2 instance.

```
oc rsh c-db2ucluster-db2u-0 su - db2inst1 -c "sh /tmp/scripts/db2configinst.sh db2inst1 50000 /mnt/blumeta0/home/db2inst1/sqllib |tee /tmp/db2configinst.out"
```

5. Create `TASDB` database.

```
oc rsh c-db2ucluster-db2u-0 su - db2inst1 -c "sh /tmp/scripts/db2createdb.sh tasdb db2inst1 US /mnt/blumeta0/home/db2inst1/sqllib tridata |tee /tmp/db2createdb.out"
```

6. Create database tablespace.

TBA to check: oc rsh c-db2ucluster-db2u-0 su - db2inst1 -c "sh /tmp/scripts/db2createts.sh"
```
oc rsh c-db2ucluster-db2u-0 su - db2inst1
cp /tmp/scripts/db2createts.sh .
./db2createts.sh
```

7. Create custom SSL

TBA to check: oc rsh c-db2ucluster-db2u-0 su - db2inst1 -c "sh /tmp/scripts/ssl-setup.sh db2inst1"

```
cp /tmp/scripts/ssl-setup.sh .
./ssl-setup.sh db2inst1
```


<!-- oc exec -ti c-db2ucluster-db2u-0 -- su - db2inst1
    export DB_SCHEMA=db2inst1
    export DB_USERNAME=tridata
    db2 connect to TASDB
    cp /tmp/create-ts.sql .
    db2 -tvf create-ts.sql 
db2 connect to tasdb user tridata using tridata
oc exec -ti c-db2ucluster-db2u-0 -- su - db2inst1 -c "sh /tmp/ssl-setup.sh db2inst1"
db2 connect to tasdb user tridata using tridata
-->

</details>

## TAS dependencies

9. Run `./dependencies.sh` ⏰: 45 minutes

## TAS

10. Run `./tas.sh` ⏰ 2-3 hours.

## Log in

11. Use URL ending in `/tririga/index.html` Username: `system` / Password is in secret: my-tririga-tas-system-user
