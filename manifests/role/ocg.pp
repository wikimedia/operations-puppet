# vim: set ts=4 et sw=4:
# role/ocg.pp
# Offline content generator for the MediaWiki collection extension

# Virtual resources for the monitoring server
@monitor_group { 'ocg_eqiad': description => 'offline content generator eqiad' }

class role::ocg::production (
    $tmpfs_size = '512M', # size of tmpfs filesystem e.g. 512M
    ) {

    system::role { 'ocg':
        description => 'offline content generator for MediaWiki Collection extension',
    }

    include passwords::redis
    include ::ocg
    include ::ocg::nagios::check
    include ocg::ganglia::module

    file { $::ocg::temp_dir:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
    }

    mount { $::ocg::temp_dir:
        ensure  => mounted,
        device  => 'tmpfs',
        fstype  => 'tmpfs',
        options => "nodev,nosuid,noexec,nodiratime,size=${tmpfs_size}",
        pass    => 0,
        dump    => 0,
        require => File[$::ocg::temp_dir],
    }


    ferm::service { 'ocg-http':
        proto  => 'tcp',
        port   => $::ocg::service_port,
        desc   => 'HTTP frontend to submit jobs and get status from pdf rendering',
        srange => $::INTERNAL
    }

    ferm::service{ 'gmond':
        proto  => 'tcp',
        port   => 8649,
        desc   => 'Ganglia monitor port (OCG config)',
        srange => $::INTERNAL
    }

    include lvs::configuration
    class { 'lvs::realserver': realserver_ips => $lvs::configuration::lvs_service_ips[$::realm]['ocg'][$::site] }
}

class role::ocg::beta {
    system::role { 'role::ocg::beta':
        description => 'offline content generator for MediaWiki Collection extension (on beta)'
    }
    include role::ocg::production
    sudo_user { 'jenkins-deploy': privileges => [
        # Need to allow jenkins-deploy to reload ocg
        'ALL = (root) NOPASSWD: /usr/sbin/service ocg stop',
        'ALL = (root) NOPASSWD: /usr/sbin/service ocg start',
        'ALL = (root) NOPASSWD: /usr/sbin/service ocg restart',
        'ALL = (root) NOPASSWD: /usr/sbin/service ocg reload'
    ] }
    # Allow ssh access from the Jenkins master to the server where cxserver is
    # running
    include contint::firewall::labs
    # Instance got to be a Jenkins slave so we can update OCG whenever a
    # change is made on mediawiki/services/ocg repository
    include role::ci::slave::labs::common
    # Also need the slave scripts for multi-git.sh
    include contint::slave-scripts
}

// Unused?
class role::ocg::test {
    system::role { 'ocg-test': description => 'offline content generator for MediaWiki Collection extension (single host testing)' }

    include passwords::redis

    $service_port = 8000

    class { '::ocg':
        redis_host         => 'localhost',
        redis_password     => $passwords::redis::ocg_test_password,
        service_port       => $service_port,
        statsd_host        => 'statsd.eqiad.wmnet',
        statsd_is_txstatsd => 1
    }

    ferm::service { 'ocg-http':
        proto  => 'tcp',
        port   => $service_port,
        desc   => 'HTTP frontend to submit jobs and get status from pdf rendering',
        srange => $::INTERNAL
    }

    class { 'redis':
        maxmemory       => '500Mb',
        password        => $passwords::redis::ocg_test_password,
    }
}
