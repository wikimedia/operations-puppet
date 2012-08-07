#!/bin/sh
# This file is maintained by Puppet
# puppet:///files/wlm/update_from_toolserver.sh

set -e

DUMP="export.`date '+%Y%m%d'`.tar.gz"
cd /var/wlm/data/
rm *.txt
wget https://toolserver.org/~erfgoed/export.tar.gz -O $DUMP
tar -xzf $DUMP

echo 'DROP TABLE IF EXISTS `monuments_all_tmp`, `admin_tree_tmp`; CREATE TABLE `monuments_all_tmp` (LIKE `monuments_all`); CREATE TABLE `admin_tree_tmp` (LIKE `admin_tree`);' | mysql wlm
mysqlimport --local --default-character-set=UTF8 wlm /var/wlm/data/admin_tree_tmp.txt /var/wlm/data/monuments_all_tmp.txt
echo 'RENAME TABLE `monuments_all` TO `monuments_all_old`, `monuments_all_tmp` TO `monuments_all`, `admin_tree` TO `admin_tree_old`, `admin_tree_tmp` TO `admin_tree`; DROP TABLE IF EXISTS `monuments_all_old`, `admin_tree_old`;' | mysql wlm

rm -f /var/wlm/cache/countries.ser

