# @summary Cloudinfra backup server
# SPDX-License-Identifier: Apache-2.0
class role::wmcs::cloudinfra_backup () {
    include profile::labs::cindermount::srv
    include profile::wmcs::cloudinfra::mariadb_backup
}
