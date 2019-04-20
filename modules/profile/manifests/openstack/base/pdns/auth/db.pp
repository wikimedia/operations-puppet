class profile::openstack::base::pdns::auth::db(
    $designate_host = hiera('profile::openstack::base::designate_host'),
    $second_region_designate_host = hiera('profile::openstack::base::second_region_designate_host'),
    $pdns_db_pass = hiera('profile::openstack::base::pdns:db_pass'),
    $pdns_admin_db_pass = hiera('profile::openstack::base::pdns::db_admin_pass'),
    Array[String] $mysql_root_clients = hiera('mysql_root_clients', []),
    ) {

    $designate_host_ip = ipresolve($designate_host,4)
    package { 'mysql-client':
        ensure => present,
    }

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

    # this override/split should probably go elsewhere, but hey
    if $::lsbdistcodename == 'stretch' {
        $mariadb_pkg = 'wmf-mariadb101'
    } else {
        $mariadb_pkg = 'wmf-mariadb10'
    }

    class { 'mariadb::packages_wmf':
        package => $mariadb_pkg,
    }

    class { 'mariadb::service':
        ensure  => 'running',
        package => $mariadb_pkg,
        manage  => true,
        enable  => true,
    }

    class { 'mariadb::config':
        config    => 'role/mariadb/mysqld_config/dns.my.cnf.erb',
        datadir   => '/srv/sqldata',
        tmpdir    => '/srv/tmp',
        read_only => 'off',
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
        srange => "(@resolve((${designate_host} ${second_region_designate_host}))
                   @resolve((${designate_host} ${second_region_designate_host}), AAAA))"
    }
}
