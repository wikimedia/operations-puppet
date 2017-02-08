#  temp. setup for testing RT migration to jessie
class role::requesttracker::upgradetest {
    system::role { 'role::requesttracker::upgradetest': description => 'temp test setup for RT migration to jessie' }

    include standard
    include ::base::firewall
    include rsync::server

    # copy db dump from slave via rsync
    $sourceip='10.64.0.20' # m1-slave.eqiad

    ferm::service { 'rt-db-rsync':
        proto  => 'tcp',
        port   => '873',
        srange => "${sourceip}/32",
    }

    rsync::server::module { 'rtdb':
        path        => '/srv/rt',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }

    # allow mysql connect from new jessie box
    ferm::service { 'rt-db-mysql':
        proto  => 'tcp',
        port   => '3306',
        srange => '208.80.154.84/32', # ununpentium
    }

    package { 'mariadb-server':
        ensure => 'present',
    }

    service { 'mysql':
        ensure => 'running',
    }

}
