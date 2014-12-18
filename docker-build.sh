#!/bin/bash

# This script will build a containerized FixMyStreet instance along with its
# supporting services
#   by: opcode0x90, 30 November 2014

set -e
error_msg() { printf "\033[31m%s\033[0m\n" "$*"; }
notice_msg() { printf "\033[33m%s\033[0m " "$*"; }
done_msg() { printf "\033[32m%s\033[0m\n" "$*"; }

if [ $# -lt 1 ]; then
  # display usage and abort script
  cat >&2 <<EOF
Usage: $0 <TAG-PREFIX>
EOF
  exit 0
fi


###############################################################################

# global variables
TAGPREFIX=$1

APP_IMAGE="perl:latest-threaded"
APP_NAME="fixmystreet"
APP_TAG="${TAGPREFIX}/${APP_NAME}"

DB_IMAGE="postgres"
DB_NAME="${APP_NAME}_db"
DB_TAG="${TAGPREFIX}/${DB_NAME}"
DB_USERNAME="fms"
DB_PASSWORD=""

###############################################################################

generate_db_password() {
  #
  # generate random password
  #
  local CHARSET="0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
  for i in {1..32}; do
    DB_PASSWORD="${DB_PASSWORD}${CHARSET:$RANDOM%${#CHARSET}:1}"
  done
}

confirm_setup() {
  #
  # confirm the generated setup before proceeding
  #
  local RESPONSE=""
  echo "This script will generate Docker containers with following setup:"
  echo
  echo "  FixMyStreet"
  echo "  -----------"
  echo "  Image: ${APP_IMAGE}"
  echo "  Tag: ${APP_TAG}"
  echo
  echo "  PostgreSQL database"
  echo "  -------------------"
  echo "  Image: ${DB_IMAGE}"
  echo "  Tag: ${DB_TAG}"
  echo "  Username: ${DB_USERNAME}"
  echo "  Password: ${DB_PASSWORD}"
  echo
  notice_msg "Is this okay? [Y/n]"

  while read RESPONSE; do
    case "${RESPONSE}" in
      "" | "Y" | "y" )
        # proceed
        break
        ;;
      "n" )
        # abort script
        exit 1
        ;;
    esac
    notice_msg "Input only 'y' or 'n':"
  done
}

build_db() {
  #
  # build Docker container for FixMyStreet PostgreSQL instance
  #
  notice_msg "Building PostgreSQL container..."; echo
  docker pull ${DB_IMAGE} || exit -1

  # copy the database script to a temporary folder
  rm -rf /tmp/fms_build/
  cp -R db/ /tmp/fms_build/
  cd /tmp/fms_build/

  # generate initialization script
  cat <<EOF > initdb.sh
    gosu postgres postgres --single -E -j fms < /script/schema.sql
    gosu postgres postgres --single -E -j fms < /script/generate_secret.sql
    gosu postgres postgres --single -E -j fms < /script/alert_types.sql
EOF

  # generate Dockerfile for building
  cat <<EOF > Dockerfile
    FROM ${DB_IMAGE}
    ENV POSTGRES_USER ${DB_USERNAME}
    ENV POSTGRES_PASSWORD ${DB_PASSWORD}
    ADD *.sql /script/
    ADD initdb.sh /docker-entrypoint-initdb.d/
EOF

  # begin building
  docker build -t "${DB_TAG}" .

  # cleanup the mess
  cd $OLDPWD
  rm -rf /tmp/fms_build/
}

###############################################################################

generate_db_password
confirm_setup

build_db

notice_msg "Done."; echo
