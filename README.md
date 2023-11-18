# my-tas-cookbook

Implementation/deployment steps for Tririga Application Suite using DB2 Warehouse on Cloud Pak for Data. TAS 11.5 based on [official documentation](https://www.ibm.com/docs/en/tas/11.5) using Bash automation created by [Arif Ali](https://www.linkedin.com/in/arifsali/) (acknowledgement: Sumit Puri).

## Git clone

```shell
git clone -b TAS_11.5-OCP_4.12-CP4D_4.6.6 --single-branch https://github.com/IBM/my-tas-cookbook.git ; cd my-tas-cookbook/TAS_11.5-OCP_4.12-CP4D_4.6.6/
```

📌 Place your AppPoint license file (license.dat) at the root of the folder.

## Cloud Pak for Data 4.6.6

📌 Open `env.sh` file and carefully update all values based on the provided instructions. This includes inserting your container software's entitlement key, your AppPoint license file's Host ID number, and storage selection based on the type of OpenShift cluster you have provisioned.

```shell
export PATH=$HOME/my-tas-cookbook/TAS_11.5-OCP_4.12-CP4D_4.6.6/cpd-cli:$PATH ; wget https://github.com/IBM/cpd-cli/releases/download/v12.0.6/cpd-cli-linux-EE-12.0.6.tgz ; tar xvf cpd-cli-linux-EE-12.0.6.tgz ; mv cpd-cli-linux-EE-12.0.6-63/ cpd-cli
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

## DB2 Warehouse 

1. Using credentials retrieved from above mentioned step, log in to Cloud Pak for Data Web Console.

<details>
<summary> 

## Expand to read more ... 

</summary>

2. From the hamburger menu, drop-down *Services*. Click on *Services catalog*. Search `db2w` and click the tile for DB2 Warehouse. Click *Provision instance* button.

3. Using the following matrix, create your database instance:

| Value                        | Key                                |
| ---------------------------- | ---------------------------------- |
| TASDB                        | Database Name                      |
| 6.1 (default)                | CPU per node for Db2 Warehouse     |
| 18 (default)                 | Memory per node for Db2 Warehouse  |
| Un checked (default)         | Deploy database on dedicated nodes |
| Single location for all data | Storage Structure                  |
| Check                        | 4K Sector Size                     |
| Check                        | Oracle compatibility               |
| Operational Analytics        | Workload                           |
| Credentials                  | Generate a Kubernetes secret       |
| ibmc-file-gold-gid  (OR)     | Storage class                      |
| ocs-storagecluster-cephfs    | Storage class                      |
| 500 GiB                      | Size                               |

**Create database user (tridata/tridata).**

4. From the hamburger menu, select *Administration - Access control*. Click *Add user* button. Create username: `tridata` with the password: `tridata`. Click Next. Select *Assign roles directly*. Click Next. Select *User* checkbox as a *Roles*. Click Next. Click *Add*.

5. From the hamburger menu, select *Services - Instances*. Click on the three-dot menu of the Db2 Warehouse-1 instance and select *Manage access*. Click the *Add users* button. Select *tridata* and choose *Admin* Role. Click *Add* button.

**Locate DB2's Instance ID number.**

6. From the hamburger menu, select *Services - Instances*. Click on the *DB2 Warehouse-1* instance. Copy the randomly generated numbered ID from the *Deployment id* field (do not copy the word `db2wh`. Only copy the randomly generated numbers).

7. Update `env.sh` with DB2W unique ID (line number 61). Save the env.sh file.


</details>


8. Run `./db2wh.sh` ⏰: 45 minutes

## TAS dependencies

9. Run `./dependencies.sh` ⏰: 45 minutes

## TAS

10. Run `./tas.sh` ⏰ 2-3 hours.

## Log in

11. Use URL ending in `/tririga/index.html` Username: `system` / Password is in secret: my-tririga-tas-system-user