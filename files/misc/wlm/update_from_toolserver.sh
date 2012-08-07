#!/bin/sh
# This file is maintained by Puppet
# puppet:///files/wlm/update_from_toolserver.sh

cd /var/wlm/data/
rm *.txt
DUMP="export.`date '+%Y%m%d'`.tar.gz"
wget https://toolserver.org/~erfgoed/export.tar.gz -O $DUMP \
        && tar -xzf $DUMP \
        && echo 'DROP TABLE IF EXISTS `monuments_all_tmp`; CREATE TABLE `monuments_all_tmp` (LIKE `monuments_all`);' | mysql wlm \
        && echo 'DROP TABLE IF EXISTS `admin_tree_tmp`; CREATE TABLE `admin_tree_tmp` (LIKE `admin_tree`);' | mysql wlm \
        && mysqlimport --local --default-character-set=UTF8 wlm /var/wlm/data/admin_tree_tmp.txt /var/wlm/data/monuments_all_tmp.txt \
        && echo 'DROP TABLE IF EXISTS `monuments_all`; DROP TABLE IF EXISTS `admin_tree`; ALTER TABLE `monuments_all_tmp` RENAME TO `monuments_all`; ALTER TABLE `admin_tree_tmp` RENAME TO `admin_tree`;' | mysql wlm

