# @summary Cloudinfra backup server
# SPDX-License-Identifier: Apache-2.0
class role::wmcs::cloudinfra_backup () {
    include profile::labs::cindermount::srv
    include profile::wmcs::cloudinfra::mariadb_backup

    # no etcd cluster in codfw1dev
    if $::wmcs_deployment == 'eqiad1' {
        include profile::wmcs::etcd::backup
    }
}
