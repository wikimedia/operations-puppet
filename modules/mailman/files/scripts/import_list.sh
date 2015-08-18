#!/bin/bash
# import a mailman list - config and archives
# dzahn@wikimedia.org - 20150814 - T108073

LISTNAME=$1
IMPORT_DIR="/var/lib/mailman/import"
INSTALL_DIR="/var/lib/mailman"
INSTALL_USER="list"

# import a list
importlist () {
 mkdir ${INSTALL_DIR}/lists/${LISTNAME}
 rsync -avp ${IMPORT_DIR}/lists/${LISTNAME}/ ${INSTALL_DIR}/lists/${LISTNAME}/
 chown root:${INSTALL_USER} ${INSTALL_DIR}/lists/${LISTNAME}

 mkdir ${INSTALL_DIR}/archives/private/${LISTNAME}
 chown root:${INSTALL_USER} ${INSTALL_DIR}/archives/private/${LISTNAME}
 rsync --remove-source-files -avp ${IMPORT_DIR}/archives/private/${LISTNAME}/ ${INSTALL_DIR}/archives/private/${LISTNAME}/

 mkdir ${INSTALL_DIR}/archives/private/${LISTNAME}.mbox
 chown root:${INSTALL_USER} ${INSTALL_DIR}/archives/private/${LISTNAME}.mbox
 rsync --remove-source-files -avp ${IMPORT_DIR}/archives/private/${LISTNAME}.mbox/ ${INSTALL_DIR}/archives/private/${LISTNAME}.mbox/

 ${INSTALL_DIR}/bin/withlist -l -r fix_url ${LISTNAME} -v
}

# check if a list is private
isprivate () {

 PRIVATE="unknown"

 if [ ! -d ${IMPORT_DIR}/archives/private/${LISTNAME} ] ; then
    echo "list not found"
    exit 1
 elif [ -h ${IMPORT_DIR}/archives/public/${LISTNAME} ] ; then
    echo "list has a public archive"
    PRIVATE="PUBLIC"
 else
    echo "list is private"
    PRIVATE="PRIVATE"
 fi
}

# usage
if [ -z ${1+x} ]; then
 echo "usage: ./import_list <listname>"
 exit 1
fi

# main
echo "checking list ${LISTNAME}"

isprivate
if [ $PRIVATE == "PUBLIC" ] ; then
    echo -e "importing ${LISTNAME}\n"
    importlist
else
    echo "skipping ${LISTNAME}"
fi

echo -e "--------------------------\n"
