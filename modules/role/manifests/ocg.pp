# vim: set ts=4 et sw=4:
# role/ocg.pp
# Offline content generator for the MediaWiki collection extension
#
# filtertags: labs-project-deployment-prep labs-project-ocg
class role::ocg {
    include ::base::firewall
    include ::standard

    # size of tmpfs filesystem
    $tmpfs_size = hiera('role::ocg::tmpfs_size', '512M')
    system::role { 'ocg':
        description => 'offline content generator for MediaWiki Collection extension',
    }

    # Set up the local redis instance + nutcracker
    require ::passwords::redis

    # Set the password from the password class
    class { '::profile::redis::master':
        password => $::passwords::redis::main_password,
    }

    $redis_pool = {
        'redis_local' => {
            auto_eject_hosts     => true,
            distribution         => 'ketama',
            redis                => true,
            redis_auth           => $passwords::redis::main_password,
            hash                 => 'md5',
            listen               => '127.0.0.1:11212',
            server_connections   => 1,
            server_failure_limit => 3,
            server_retry_timeout => to_milliseconds('30s'),
            timeout              => 1000,
            server_map           => hiera('role::ocg::redis_servers'),
        }
    }

    class { 'nutcracker':
        mbuf_size => '64k',
        pools     => $redis_pool,
    }

    class { '::nutcracker::monitoring': }

    include ::ocg
    include ::ocg::nagios

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
        proto   => 'tcp',
        port    => $::ocg::service_port,
        desc    => 'HTTP frontend to submit jobs and get status from pdf rendering',
        srange  => '$DOMAIN_NETWORKS',
        notrack => true,
    }

    ferm::service{ 'gmond':
        proto  => 'tcp',
        port   => 8649,
        desc   => 'Ganglia monitor port (OCG config)',
        srange => '$DOMAIN_NETWORKS',
    }

    include lvs::configuration
    class { '::lvs::realserver': realserver_ips => $lvs::configuration::service_ips['ocg'][$::site] }
}
