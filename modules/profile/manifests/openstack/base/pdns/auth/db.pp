class profile::openstack::base::pdns::auth::db(
    $designate_host = hiera('profile::openstack::base::designate_host'),
    $pdns_db_pass = hiera('profile::openstack::base::pdns:db_pass'),
    $pdns_admin_db_pass = hiera('profile::openstack::base::pdns::db_admin_pass'),
    ) {

    $designate_host_ip = ipresolve($designate_host,4)
    package { 'mysql-client':
        ensure => present,
    }

    # install mysql locally on all dns servers
    include ::profile::mariadb::monitor::dba
    # for DBA admin root purposes
    ferm::rule { 'mariadb_dba':
        rule => 'saddr ($MYSQL_ROOT_CLIENTS) proto tcp dport (3306) ACCEPT;',
    }

    # Note:  This will install mariadb but won't set up the
    #  pdns database.  Manual steps are:
    #
    #  $ /opt/wmf/mariadb/scripts/mysql_install_db
    #  Then export the 'pdns' db from a working labservices host and import
    #  Then, run 'designate-manage powerdns sync' for the new host
    #
    class { 'mariadb::packages_wmf':
        package => 'wmf-mariadb10',
    }

    class { 'mariadb::service':
        ensure  => 'running',
        package => 'wmf-mariadb10',
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
        srange => $designate_host_ip,
    }
}
