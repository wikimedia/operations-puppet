# SPDX-License-Identifier: Apache-2.0
# @summary This profile installs a local mysql DB for debmonitor-dev
class profile::debmonitor::localdb ()
{
    ensure_packages('mariadb-server')

    # Puppetise a config snippet to ensure that mariadb not only
    # listens on localhost, but also on it's full IP (as required
    # by the DB grants)
    file { '/etc/mysql/mariadb.conf.d/70-bind-on-full-ip.cnf':
        mode    => '0644',
        content => template('profile/debmonitor/mariadb.erb'),
        require => Package['mariadb-server'],
    }
}
