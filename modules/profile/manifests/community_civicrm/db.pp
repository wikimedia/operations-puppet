# SPDX-License-Identifier: Apache-2.0
# sets up a database for community crm instance
class profile::community_civicrm::db {

    class { '::mariadb::packages': }

    class { '::mariadb::config':
        basedir => '/usr',
        config  => 'profile/community_civicrm/community-civi.my.cnf.erb',
        datadir => '/var/lib/mysql',
    }

}
