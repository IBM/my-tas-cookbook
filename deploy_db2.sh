#!/usr/bin/bash
set -e 
## To read env.sh file.
source $(dirname $(realpath ${0}))/env.sh
## Check env.sh
if [ -z "$DB2_NAME" ] ; then
  echo "The name for the DB2 installation must be defined in the env.sh file."
  exit 1
fi
## Delete DB2
cat <<\EOF > delete_db2.sh
#!/usr/bin/bash

## Copyright (C) 2022 Arif Ali
## This program is free software: you can redistribute it and/or modify it under the terms 
## of the GNU General Public License as published by the Free Software Foundation, 
## either version 3 of the License, or (at your option) any later version. 
## This program is distributed in the hope that it will be useful, 
## but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
## or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License 
## for more details. You should have received a copy of the GNU General Public License 
## along with this program. If not, see https://www.gnu.org/licenses/.

## Exit out of an error
set -e

## To read env.sh file.
source $(dirname $(realpath ${0}))/env.sh

oc project ${DB2_NAME}
envsubst < db2-roks.yaml | oc delete -f -
oc delete project ${DB2_NAME}
rm db2-roks.yaml delete_db2.sh
EOF
chmod 755 delete_db2.sh
## Create new project, service account. Grant privileged SCC and create DB2 instance.
oc new-project ${DB2_NAME}
oc create serviceaccount ${DB2_NAME}
oc adm policy add-scc-to-user privileged -n ${DB2_NAME} -z ${DB2_NAME}
## Create deployment YAML
cat <<\EOF > db2-roks.yaml
apiVersion: v1
kind: Secret
metadata:
  name: ${DB2_NAME}-secret
  namespace: ${DB2_NAME}
data:
  DB2INST1_PASSWORD: ZGIyaW5zdDE=  #db2inst1
type: Opaque

---

apiVersion: v1
kind: Service
metadata:
  name: ${DB2_NAME}-ci
spec:
  type: ClusterIP
  selector:
    app: ${DB2_NAME}
  ports:
    - name: ${DB2_NAME}-http
      protocol: TCP
      port: 50000
      targetPort: 50000
    - name: ${DB2_NAME}-https
      protocol: TCP
      port: 50001
      targetPort: 50001

---

apiVersion: v1
kind: Service
metadata:
  name: ${DB2_NAME}-np
spec:
  type: NodePort
  selector:
    app: ${DB2_NAME}
  ports:
    - name: ${DB2_NAME}-http
      protocol: TCP
      port: 50000
      targetPort: 50000
    - name: ${DB2_NAME}-https
      protocol: TCP
      port: 50001
      targetPort: 50001

---

# apiVersion: v1
# kind: Service
# metadata:
#   name: ${DB2_NAME}-lb
# spec:
#   selector:
#     app: ${DB2_NAME}
#   type: LoadBalancer
#   ports:
#     - name: ${DB2_NAME}-http
#       protocol: TCP
#       port: 50000
#       targetPort: 50000
#     - name: ${DB2_NAME}-https
#       protocol: TCP
#       port: 50001
#       targetPort: 50001

---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: ${DB2_NAME}
spec:
  to:
    kind: Service
    name: ${DB2_NAME}-ci
    weight: 100
  port:
    targetPort: db2-http
  tls:
    termination: passthrough
    insecureEdgeTerminationPolicy: Redirect
  wildcardPolicy: None
---

apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: ${DB2_NAME}
spec:
  selector:
    matchLabels:
      app: ${DB2_NAME}
  serviceName: "${DB2_NAME}"
  replicas: 1
  template:
    metadata:
      labels:
        app: ${DB2_NAME}
    spec:
      serviceAccount: ${DB2_NAME}
      containers:
      - name: ${DB2_NAME}
        securityContext:
          privileged: true
#        image: ibmcom/db2:11.5.5.1
        image: icr.io/db2_community/db2
        env:
        - name: DB2INST1_PASSWORD
          valueFrom:
            secretKeyRef: 
              name: ${DB2_NAME}-secret
              key: DB2INST1_PASSWORD
        - name: LICENSE 
          value: accept 
        - name: DB2INSTANCE 
          value: db2inst1       
        ports:
        - containerPort: 50000
          name: ${DB2_NAME}-http
        - containerPort: 50001
          name: ${DB2_NAME}-https
        imagePullPolicy: IfNotPresent
        volumeMounts:
        - mountPath: /database
          name: db2vol
  volumeClaimTemplates:
  - metadata:
      name: db2vol
    spec:
      accessModes:
      - ReadWriteMany
      resources:
        requests:
          storage: 500Gi
      storageClassName: ${STG_CLASS_BLOCK}
EOF
## Deploy
envsubst < db2-roks.yaml | oc create -f -
while [ "$DEPLOY_DB2" != "True" ]; do DEPLOY_DB2=$(oc get pods ${DB2_NAME}-0 -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}'); echo "Installig DB2...Wait!" $DEPLOY_DB2; sleep 1; done
oc logs -f ${DB2_NAME}-0