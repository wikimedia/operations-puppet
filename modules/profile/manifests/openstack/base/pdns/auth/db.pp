# SPDX-License-Identifier: Apache-2.0
class profile::openstack::base::pdns::auth::db(
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::base::designate_hosts'),
    $pdns_db_pass = lookup('profile::openstack::base::pdns:db_pass'),
    $pdns_admin_db_pass = lookup('profile::openstack::base::pdns::db_admin_pass'),
    Array[String] $mysql_root_clients = lookup('mysql_root_clients', {'default_value' => []}),
){

    $designate_host_ips = $designate_hosts.map |$host| { ipresolve($host, 4) }

    # install mysql locally on all dns servers
    include ::profile::mariadb::monitor::dba
    # for DBA admin root purposes
    $mysql_root_clients_str = join($mysql_root_clients, ' ')
    ferm::rule { 'mariadb_dba':
        rule => "saddr (${mysql_root_clients_str}) proto tcp dport (3306) ACCEPT;",
    }

    # Note:  This will install mariadb but won't set up the
    #  pdns database.  Manual steps are:
    #
    #  $ /opt/wmf/mariadb/scripts/mysql_install_db
    #  Then export the 'pdns' db from a working labservices host and import
    #  Then, run 'designate-manage powerdns sync' for the new host
    #
    #  The by-hand bootstrap instructions can be found at
    #   https://computingforgeeks.com/install-powerdns-and-powerdns-admin-on-ubuntu-18-04-debian-9-mariadb-backend/
    #

    require profile::mariadb::packages_wmf
    include profile::mariadb::wmfmariadbpy

    package { 'default-mysql-client':
        ensure => present,
    }

    class { 'mariadb::service':
        ensure => 'running',
        manage => true,
        enable => true,
    }

    class { 'mariadb::config':
        config    => 'role/mariadb/mysqld_config/dns.my.cnf.erb',
        datadir   => '/srv/sqldata',
        tmpdir    => '/srv/tmp',
        read_only => 'off',
        basedir   => $profile::mariadb::packages_wmf::basedir
,
    }

    file { '/etc/mysql/production-grants-dns.sql':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('role/mariadb/grants/dns.sql.erb'),
    }

    # Allow mysql access from the designate host so it can send domain updates.
    ferm::service { 'mysql_designate':
        proto  => 'tcp',
        port   => '3306',
        srange => "(@resolve((${join($designate_hosts,' ')}))
                   @resolve((${join($designate_hosts,' ')}), AAAA))"
    }

    backup::set { 'mysql-srv-backups-dumps-latest': }
    class { '::pdns_server::db_backups':  }
}
