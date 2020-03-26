#!/bin/bash

SCRIPTNAME=$0
ARGUMENT=$1

# GeoIP URL + filenames
BASE_URL='https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2'
DB_CITY='City'
DB_COUNTRY='Country'
DB_ASN='ASN'
LICENSE_KEY='<YOUR-LICENSE-KEY>'

# Directories:
DOWNLOADDIR='/tmp/maxmind'
GEOIP_DIR='/usr/share/GeoIP'

sanity_checks() {
    # Are we root?
    if [ ${UID} -ne 0 ]; then
        logger -t user.info -s "${SCRIPTNAME}: you need to run this script as root or using sudo."
        exit 1
    fi

    # Create DOWNLOADDIR if not present
    if [ ! -d ${DOWNLOADDIR} ]; then
        mkdir ${DOWNLOADDIR}
    fi

    # Create GEOIP_DIR if not present
    if [ ! -d ${GEOIP_DIR} ]; then
        mkdir ${GEOIP_DIR}
    fi

}

downloaddb() {
    current_db=$1

    # Syslog that we start working on the current db
    logger -t user.info -s "${SCRIPTNAME}: Start working on: GeoLite2-${current_db}"

    # Getting the DB + checksum file
    echo "DB: ${current_db}"
    WGET_URL="${BASE_URL}-${current_db}"'&license_key='"${LICENSE_KEY}"'&suffix=tar.gz'
    TARGET_FILE="${DOWNLOADDIR}/${current_db}"
    wget ${WGET_URL} -O ${TARGET_FILE}
    wget ${WGET_URL}.md5 -O ${TARGET_FILE}.md5

    # Calculate DB checksum and compare to checksum file
    CALC_DB_MD5=$( md5sum ${DOWNLOADDIR}/${current_db} | awk '{print $1}' )
    DB_MD5=$( cat ${TARGET_FILE}.md5 )

    # Compare calculated checksum to checksum file. If no match, syslog error msg and exit
    if [ x"${CALC_DB_MD5}" != x"${DB_MD5}" ]; then
        logger -t user.error -s "${SCRIPTNAME}: ${current_db} checksum does not match provided checksum."
        exit 1
    fi

    # Unpack mmdb file from DB file
    tar -xzf ${TARGET_FILE} -C ${DOWNLOADDIR} --wildcards *.mmdb

    # Get full path to mmdb file
    MMDB_FILEPATH=$( find ${DOWNLOADDIR}/ -type f -name *.mmdb -print )

    # Copy file into place if different from already current file
    MMDB_FILENAME=$( basename ${MMDB_FILEPATH} )

    # Calculate checksum for current "installed" DB file if it exists
    if [ -f ${GEOIP_DIR}/${MMDB_FILENAME} ]; then
        CALC_OLD_DB_MD5=$( md5sum ${GEOIP_DIR}/${MMDB_FILENAME} | awk '{print $1}' )
    else
        CALC_OLD_DB_MD5='nosuchfile'
    fi

    # Copy file into place if different from already current file
    if [ x"${CALC_OLD_DB_MD5}" != x"${DB_MD5}" ]; then
        cp ${MMDB_FILEPATH} ${GEOIP_DIR}/
        logger -t user.info -s "${SCRIPTNAME}: Updated local file using: GeoLite2-${current_db}"
    fi

    # Cleanup DOWNLOADDIR
    rm -rf ${DOWNLOADDIR}/*

    # Syslog that we finished working on the current db
    logger -t user.info -s "${SCRIPTNAME}: Finished working on: GeoLite2-${current_db}"
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

update_dbs() {
    for DB in ${DB_ASN} ${DB_CITY} ${DB_COUNTRY}; do
        downloaddb ${DB}
    done
}

usage() {
    echo "Usage: ${SCRIPTNAME} <cc|asn|all>"
    echo "   cc  - City/Country DB update"
    echo "   asn - ASN DB update"
    echo "   all - ASN/City/Country DB update"
}

################
# MAIN PROGRAM #
################
sanity_checks

case "${ARGUMENT}" in
    cc)
        ccdb
        ;;
    asn)
        asndb
        ;;
    all)
        update_dbs
        ;;
    *)
        usage
        ;;
esac

exit 0
