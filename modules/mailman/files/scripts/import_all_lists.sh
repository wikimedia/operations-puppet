#!/bin/bash
# import all lists found in import directory

INSTALL_DIR="/var/lib/mailman"
IMPORT_DIR="/var/lib/mailman/import"

for list in $(find ${IMPORT_DIR}/lists -maxdepth 1) ; do

    LISTNAME=$(basename $list)
    ${INSTALL_DIR}/import_list.sh $LISTNAME all
done

echo "done importing. running list_lists\n"
${INSTALL_DIR}/bin/list_lists

echo "importing held messages\n"
rsync -avp /var/lib/mailman/import/data/ /var/lib/mailman/data/

echo "importing qfiles\n"
rsync -avp /var/lib/mailman/import/qfiles/ /var/lib/mailman/qfiles/
