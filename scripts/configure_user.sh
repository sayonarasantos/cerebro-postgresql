#!/bin/bash


#### Script to create and configure database users
## Requirements: install the psql package and configure the variables,
## with .bashrc:
# export PROD_DB_HOST=
# export PROD_DB_PORT=
# export PROD_DB_USER_ADMIN=
# export TEST_DB_HOST=
# export TEST_DB_PORT=
# export TEST_DB_USER_ADMIN=
##  or here (uncomment the following lines):
# PROD_DB_HOST=
# PROD_DB_PORT=5432
# PROD_DB_USER_ADMIN=
# TEST_DB_HOST=
# TEST_DB_PORT=5432
# TEST_DB_USER_ADMIN=


function configure_access(){
    case $environment_id in
        test )
            host=$TEST_DB_HOST
            port=$TEST_DB_PORT
            useradmin=$TEST_DB_USER_ADMIN
            ;;
        prod )
            host=$PROD_DB_HOST
            port=$PROD_DB_PORT
            useradmin=$PROD_DB_USER_ADMIN
            ;;
        * )
            printf "* The environment-id value is an invalid option.\n"
            exit 1
            ;;
    esac
}


function get_user(){
    if [[ $create_user == "true" ]]; then
        password=$(openssl rand -base64 16)
        sqlcmd_create_user="CREATE USER $username WITH ENCRYPTED PASSWORD '$password';"
    else
        sqlcmd_create_user=''
    fi
}


function get_permissions(){
    case $role in
        dev )
            permissions_model="
                GRANT USAGE ON SCHEMA $schema TO $username;
                GRANT SELECT ON ALL TABLES IN SCHEMA $schema TO $username;
                GRANT SELECT ON ALL SEQUENCES IN SCHEMA $schema TO $username;
                ALTER DEFAULT PRIVILEGES IN SCHEMA $schema GRANT SELECT ON TABLES TO $username;"
            ;;
        app )
            permissions_model="
                GRANT USAGE ON SCHEMA $schema TO $username;
                GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA $schema TO $username;
                GRANT SELECT, UPDATE, USAGE ON ALL SEQUENCES IN SCHEMA $schema TO $username;
                ALTER DEFAULT PRIVILEGES IN SCHEMA $schema GRANT SELECT, UPDATE, INSERT, DELETE ON TABLES TO $username;"
            ;;
        adm )
            permissions_model="
                GRANT USAGE, CREATE ON SCHEMA $schema TO $username;
                GRANT SELECT, UPDATE, INSERT, DELETE, REFERENCES ON ALL TABLES IN SCHEMA $schema TO $username;
                GRANT SELECT, UPDATE, USAGE ON ALL SEQUENCES IN SCHEMA $schema TO $username;
                ALTER DEFAULT PRIVILEGES IN SCHEMA $schema GRANT SELECT, UPDATE, INSERT, DELETE, REFERENCES ON TABLES TO $username;"
            ;;
        * )
            printf "* The role value is invalid option.\n"
            exit 1
    esac
}


function execute_sqlcmd(){
    sqlcmd_full="
                $sqlcmd_create_user
                GRANT CONNECT ON DATABASE $database TO $username;"

    for sch in $schemas; do
        schema=$sch
        get_permissions
        sqlcmd_full="$sqlcmd_full $permissions_model"
    done

    # printf "* SQL command:\n\n  $sqlcmd_full\n" | sed 's/\;/\;\n /g'
    printf "\n* SQL command:$sqlcmd_full\n\n"

    psql -t -A -h "$host" -U "$useradmin" -d "$database" -c "$sqlcmd_full"
}




create_user="false"
mandatory_args=5
help_msg="
* This script create and configure database users.
  Usage:
    configure_user_advanced [MANDATORY ARGUMENTS]... [OPTIONAL ARGUMENTS]

  Example:
    ./configure_user_advanced.sh -i test -d data_test -u beyonce -r adm -s 'schema1 schema2' -c

  MANDATORY ARGUMENTS:
    -i | --environment-id    Server database environment-id. Options: test or prod.
    -d | --database         Database name that will be configured. Example: data_test.
    -u | --username         User that will be configured. Example: beyonce.
    -r | --role             User role. Options: dev, app or adm.
                                - dev: Simple user (Only SELECT permission)
                                - app: User for application (SELECT, UPDATE, INSERT, DELETE permissions)
                                - adm: Administrator user (SELECT, UPDATE, INSERT, DELETE and REFERENCES permissions)
    -s | --schemas          Schemes that will be allowed. Example: 'schema1 schema2 schemas3'.

  OPTIONAL ARGUMENTS:
    -c | --create-user      Booolean parameter. User if you want create a new user.
        -h | --help             Prints this help.\n\n"


if [[ -x "$(psql --version)" ]]; then
    printf "* Install the psql package before use this script.\n"
    exit 1
fi

if [[ -z $PROD_DB_HOST || -z $TEST_DB_HOST || -z $PROD_DB_USER_ADMIN || -z $TEST_DB_USER_ADMIN ]]; then
    printf "* Configure variables before use this script.\n"
    exit 1
fi

if [ "$1" != "-h" ] && [ "$1" != "--help" ]; then
    if [[ "$#" -lt $mandatory_args ]]; then
        printf "* Mandatory arguments are missing.\n"
        exit 1
    fi
fi

while [[ ! -z "$1" ]]; do
    case $1 in
        -i | --environment-id ) shift
                        environment_id=$1
                        ;;
        -d | --database )
                        shift
                        database=$1
                        ;;
        -u | --username )
                        shift
                        username=$1
                        ;;
        -r | --role )
                        shift
                        role=$1
                        ;;
        -s | --schemas )
                        shift
                        schemas=$1
                        ;;
        -c | --create-user )
                        create_user="true"
                        ;;
        -h | --help )
                        printf "${help_msg}"
                        exit 0
                        ;;
        * )      
                        echo "* Invalid argument $1."
                        printf "${help_msg}"
                        exit 1
                      ;;
    esac
    shift
done

configure_access

get_user

get_permissions

execute_sqlcmd

if [[ "$?" == 0 ]] && [[ $create_user == "true" ]]; then
    printf "\n* Access infomation for the new user:
  - Database: $database
  - Usermane: $username
  - Passord: $password
  - Port: $port
  - Host: $host\n\n"
fi