#!/bin/sh
# This file is maintained by Puppet
# puppet:///files/wlm/update_from_toolserver.sh

wget http://toolserver.org/~erfgoed/monuments.sql.gz -O /tmp/monuments.sql.gz \
        && gunzip -c /tmp/monuments.sql.gz | sed -e 's/`monuments_all`/`monuments_all_tmp`/' -e 's/`admin_tree`/`admin_tree_tmp`/' | mysql wlm \
        && echo 'DROP TABLE IF EXISTS `monuments_all`; DROP TABLE IF EXISTS `admin_tree`; ALTER TABLE `monuments_all_tmp` RENAME TO `monuments_all`; ALTER TABLE `admin_tree_tmp` RENAME TO `admin_tree`;' | mysql wlm

