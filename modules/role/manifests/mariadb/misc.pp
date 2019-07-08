# miscellaneous services clusters
class role::mariadb::misc(
    $shard  = 'm1',
    $master = false,
    ) {

    system::role { 'mariadb::misc':
        description => "Misc Services Database ${shard}",
    }

    $read_only = $master ? {
        true  => 0,
        false => 1,
    }

    $mysql_role = $master ? {
        true  => 'master',
        false => 'slave',
    }

    include ::profile::standard
    include ::profile::mariadb::monitor
    include ::passwords::misc::scripts
    include ::profile::base::firewall
    ::profile::mariadb::ferm { 'misc': }
    # hack until m5 servers are bought and proxy is in use
    if $shard == 'm5' {
        include ::profile::mariadb::ferm_wmcs
    }
    class { 'profile::mariadb::monitor::prometheus':
        mysql_group => 'misc',
        mysql_shard => $shard,
        mysql_role  => $mysql_role,
    }

    include mariadb::packages_wmf
    include mariadb::service

    class { 'mariadb::config':
        config    => 'role/mariadb/mysqld_config/misc.my.cnf.erb',
        basedir   => '/opt/wmf-mariadb101',
        datadir   => '/srv/sqldata',
        tmpdir    => '/srv/tmp',
        ssl       => 'puppet-cert',
        read_only => $read_only,
        p_s       => 'on',
    }

    class { 'profile::mariadb::grants::production':
        shard    => $shard,
        prompt   => "MISC ${shard}",
        password => $passwords::misc::scripts::mysql_root_pass,
    }

    class { 'mariadb::heartbeat':
        shard      => $shard,
        datacenter => $::site,
        enabled    => $master,
    }
}

