#!/bin/bash

SCRIPTNAME=$0
ARGUMENT=$1

BASE_URL='https://geolite.maxmind.com/download/geoip/database'
DB_CITY='GeoLite2-City.tar.gz'
DB_COUNTRY='GeoLite2-Country.tar.gz'
DB_ASN='GeoLite2-ASN.tar.gz'

DOWNLOADDIR='/tmp/maxmind'
GEOIP_DIR='/usr/share/GeoIP'


downloaddb() {
    current_db=$1

    if [ ! -d ${DOWNLOADDIR} ]; then
        mkdir ${DOWNLOADDIR}
    fi

    # Getting the DB + checksum file
    echo "DB: ${current_db}"
    WGET_URL="${BASE_URL}/${current_db}"
    TARGET_FILE="${DOWNLOADDIR}/${current_db}"
    wget ${WGET_URL} -O ${TARGET_FILE}
    wget ${WGET_URL}.md5 -O ${TARGET_FILE}.md5

    # Calculate DB checksum and compare to checksum file
    CALC_DB_MD5=$( md5sum ${DOWNLOADDIR}/${current_db} | awk '{print $1}' )
    DB_MD5=$( cat ${TARGET_FILE}.md5 )

    # Compare calculated checksum to checksum file. If no match, syslog error msg and exit
    if [ x"${CALC_DB_MD5}" != x"${DB_MD5}" ]; then
        logger -t user.error -s "${SCRIPTNAME}: ${current_db} checksum does not match provided checksum."
        exit 0
    fi

    # Unpack mmdb file from DB file
    tar -xzf ${TARGET_FILE} -C ${DOWNLOADDIR} --wildcards *.mmdb

    # Get full path to mmdb file
    MMDB_FILEPATH=$( find ${DOWNLOADDIR}/ -type f -name *.mmdb -print )
    echo ${MMDB_FILEPATH}

    # Copy file into place
    cp ${MMDB_FILEPATH} ${GEOIP_DIR}

    # Cleanup DOWNLOADDIR
    rm -rf ${DOWNLOADDIR}/*
}

ccdb() {
    for DB in ${DB_CITY} ${DB_COUNTRY}; do
        downloaddb ${DB}
    done
}

asndb() {
    for DB in ${DB_ASN}; do
        downloaddb ${DB}
    done
}

usage() {
    echo "Usage: ${SCRIPTNAME} <cc|asn>"
    echo "   cc  - City/Country DB update"
    echo "   asn - ASN DB update"
}

case "${ARGUMENT}" in
    cc)
        ccdb
        ;;
    asn)
        asndb
        ;;
    *)
        usage
        ;;
esac

