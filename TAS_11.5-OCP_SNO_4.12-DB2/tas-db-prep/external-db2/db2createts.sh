#!/bin/bash

# Replace these variables with your DB2 credentials and configuration
DB_USER=tridata
DB_PASSWORD=tridata
DB_NAME=tasdb
DB_SCHEMA=db2inst1

# DB2 SQL commands
SQL_COMMANDS=$(cat <<EOF
CONNECT TO $DB_NAME;
COMMIT WORK;

-- DDL Statements for BUFFERPOOLS
CREATE BUFFERPOOL "TRIBUFPOOL" SIZE AUTOMATIC PAGESIZE 32768;
CREATE BUFFERPOOL "TRIBUFPOOLINDEX" SIZE AUTOMATIC PAGESIZE 32768;
CREATE BUFFERPOOL "TRITEMPBP" SIZE AUTOMATIC PAGESIZE 32768;
CREATE BUFFERPOOL "DEDICATEDBPDATA" SIZE AUTOMATIC PAGESIZE 32768;
CREATE BUFFERPOOL "DEDICATEDBPINDX" SIZE AUTOMATIC PAGESIZE 32768;
CREATE BUFFERPOOL "DEDICATEDBPLOB" SIZE AUTOMATIC PAGESIZE 32768;

-- DDL Statements for TABLESPACES
CREATE LARGE TABLESPACE "TRIDATA_DATA" IN DATABASE PARTITION GROUP IBMDEFAULTGROUP
         PAGESIZE 32768 MANAGED BY AUTOMATIC STORAGE
         AUTORESIZE YES
         INITIALSIZE 5000 M
         INCREASESIZE 1 G
         MAXSIZE NONE
         EXTENTSIZE 32
         PREFETCHSIZE AUTOMATIC
         BUFFERPOOL "TRIBUFPOOL"
         DATA TAG INHERIT
         OVERHEAD INHERIT
         TRANSFERRATE INHERIT
         DROPPED TABLE RECOVERY ON;

CREATE LARGE TABLESPACE "TRIDATA_INDX" IN DATABASE PARTITION GROUP IBMDEFAULTGROUP
         PAGESIZE 32768 MANAGED BY AUTOMATIC STORAGE
         AUTORESIZE YES
         INITIALSIZE 5000 M
         MAXSIZE NONE
         EXTENTSIZE 32
         PREFETCHSIZE AUTOMATIC
         BUFFERPOOL "TRIBUFPOOLINDEX"
         DATA TAG INHERIT
         OVERHEAD INHERIT
         TRANSFERRATE INHERIT
         DROPPED TABLE RECOVERY ON;

CREATE TEMPORARY TABLESPACE "TRITEMP" IN DATABASE PARTITION GROUP IBMTEMPGROUP
         PAGESIZE 32768 MANAGED BY AUTOMATIC STORAGE
         EXTENTSIZE 32
         PREFETCHSIZE AUTOMATIC
         BUFFERPOOL "TRITEMPBP"
         OVERHEAD INHERIT
         TRANSFERRATE INHERIT
         FILE SYSTEM CACHING
         DROPPED TABLE RECOVERY OFF;

CREATE LARGE TABLESPACE "DEDICATED_DATA" IN DATABASE PARTITION GROUP IBMDEFAULTGROUP
         PAGESIZE 32768 MANAGED BY AUTOMATIC STORAGE
         AUTORESIZE YES
         INITIALSIZE 5000 M
         MAXSIZE NONE
         EXTENTSIZE 32
         PREFETCHSIZE AUTOMATIC
         BUFFERPOOL "DEDICATEDBPDATA"
         DATA TAG INHERIT
         OVERHEAD INHERIT
         TRANSFERRATE INHERIT
         DROPPED TABLE RECOVERY ON;

CREATE LARGE TABLESPACE "DEDICATED_INDEX" IN DATABASE PARTITION GROUP IBMDEFAULTGROUP
         PAGESIZE 32768 MANAGED BY AUTOMATIC STORAGE
         AUTORESIZE YES
         INITIALSIZE 5000 M
         MAXSIZE NONE
         EXTENTSIZE 32
         PREFETCHSIZE AUTOMATIC
         BUFFERPOOL "DEDICATEDBPINDX"
         DATA TAG INHERIT
         OVERHEAD INHERIT
         TRANSFERRATE INHERIT
         DROPPED TABLE RECOVERY ON;

CREATE LARGE TABLESPACE "DEDICATED_LOBS" IN DATABASE PARTITION GROUP IBMDEFAULTGROUP
         PAGESIZE 32768 MANAGED BY AUTOMATIC STORAGE
         AUTORESIZE YES
         INITIALSIZE 5000 M
         MAXSIZE NONE
         EXTENTSIZE 32
         PREFETCHSIZE AUTOMATIC
         BUFFERPOOL "DEDICATEDBPLOB"
         DATA TAG INHERIT
         OVERHEAD INHERIT
         TRANSFERRATE INHERIT
         DROPPED TABLE RECOVERY ON;

CREATE USER TEMPORARY TABLESPACE "SYSTOOLSTMPSPACE" IN DATABASE PARTITION GROUP IBMCATGROUP
        PAGESIZE 32768 MANAGED BY AUTOMATIC STORAGE
        USING STOGROUP "IBMSTOGROUP"
        EXTENTSIZE 4
        PREFETCHSIZE AUTOMATIC
        BUFFERPOOL "IBMDEFAULTBP"
        OVERHEAD INHERIT
        TRANSFERRATE INHERIT
        FILE SYSTEM CACHING
        DROPPED TABLE RECOVERY OFF;

-- CREATE SCHEMA
CREATE SCHEMA $DB_SCHEMA AUTHORIZATION $DB_USER;

COMMIT WORK;
CONNECT RESET;
TERMINATE;
EOF
)

# Run SQL commands using db2 command-line tool
echo "$SQL_COMMANDS" | db2 -tv -z db2_output.log

# Check for errors in the db2 command execution
if [ $? -eq 0 ]; then
  echo "DB2 commands executed successfully."
else
  echo "Error: Failed to execute DB2 commands. Check db2_output.log for details."
fi