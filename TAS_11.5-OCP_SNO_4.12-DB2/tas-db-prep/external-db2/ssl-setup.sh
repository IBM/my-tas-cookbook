#!/bin/sh

# INSTANCE=${1}

# # Add gskit libraries in the PATH
# export PATH="/home/$INSTANCE/sqllib/gskit/bin:$PATH"

INST_USER=${1}

# validate instance user exist

instHome=`perl -e "@user=getpwnam ${INST_USER};" -e "print @user[7];"`

if [ -z "$instHome" ]; then
    echo "Error: The DB2 instance user $INST_USER does not exist!"
    exit 1
fi
if [ ! -d "$instHome" ] ; then
    echo "Error: The DB2 instance user $INST_USER, home directory does not exist."
    exit 1
fi

# validate running as instance user

if [[ `whoami` != "$INST_USER" ]]; then
	echo "Error: this script needs to be run as the instance user, $INST_USER"
	exit 1
fi

ok=0

# run instance profile 

echo "Execute the instance profile..."
echo ". ${instHome}/sqllib/db2profile"
. ${instHome}/sqllib/db2profile
rc=$?
if [ "$rc" -ne "0" ]; then
    echo "Error unable to execute the instance profile, rc = $rc"
    ok=$rc
else
	echo "Return code for execute the instance profile is $rc"
fi

# Generate Key Database and Certificate:
mkdir ${instHome}/dbcerts
cd ${instHome}/dbcerts
gsk8capicmd_64 -keydb -create -db "mydbserver.kdb" -pw "Passw0rd01" -stash
gsk8capicmd_64 -cert -create -db "mydbserver.kdb" -pw "Passw0rd01" -label "myselfsigned" -dn "CN=myhost.mycompany.com,O=myOrganization,OU=myOrganizationUnit,L=myLocation,ST=ON,C=CA"
gsk8capicmd_64 -cert -extract -db "mydbserver.kdb" -pw "Passw0rd01" -label "myselfsigned" -target "mydbserver.arm" -format ascii -fips
gsk8capicmd_64 -cert -extract -db "mydbserver.kdb" -pw "Passw0rd01" -label "myselfsigned" -target "rootCA.pem" -format ascii
# Update DB2 settings
db2 update dbm cfg using SSL_SVR_KEYDB ${instHome}/dbcerts/mydbserver.kdb
db2 update dbm cfg using SSL_SVR_STASH ${instHome}/dbcerts/mydbserver.sth
db2 update dbm cfg using SSL_SVR_LABEL myselfsigned
db2 update dbm cfg using SVCENAME 50000
db2 update dbm cfg using SSL_SVCENAME 50001
db2 update dbm cfg using SSL_VERSIONS TLSV12
db2set -i db2inst1 DB2COMM=SSL

# Start & Stop for changes to take effect
db2stop
db2start

# Check DB2 configuration
db2 get dbm config | grep SVCE
db2 get dbm config | grep SSL
db2set -all | grep DB2COMM
echo "Ensure 50001 is listening"
netstat -nlp

# Display Certificate
cat rootCA.pem

exit 0