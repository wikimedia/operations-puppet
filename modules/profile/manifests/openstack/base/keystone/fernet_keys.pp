class profile::openstack::base::keystone::fernet_keys(
    Array[Stdlib::Fqdn] $keystone_hosts = lookup('profile::openstack::base::openstack_controllers'),
    String $rotate_time = lookup('profile::openstack::base::rotate_time'),
    String $sync_time = lookup('profile::openstack::base::sync_time'),
    ) {

    systemd::timer::job { 'keystone_rotate_keys':
        description        => 'Rotate keys for Keystone fernet tokens',
        command            => '/usr/bin/keystone-manage fernet_rotate --keystone-user keystone --keystone-group keystone',
        interval           => {
            'start'    => 'OnCalendar',
            'interval' => "*-*-* ${rotate_time}",
        },
        logging_enabled    => true,
        user               => 'root',
        monitoring_enabled => false,
    }

    file { '/etc/keystone/fernet-keys':
        ensure => directory,
        owner  => 'keystone',
        group  => 'keystone',
        mode   => '0770',
    }

    rsync::server::module { 'keystonefernetkeys':
        path        => '/etc/keystone/fernet-keys',
        uid         => 'keystone',
        gid         => 'keystone',
        hosts_allow => $keystone_hosts,
        auto_ferm   => true,
        read_only   => true,
    }

    $other_hosts = $keystone_hosts - $::fqdn
    $other_hosts.each |String $thishost| {
        systemd::timer::job { "keystone_sync_keys_to_${thishost}":
            description        => "Sync keys for Keystone fernet tokens to ${thishost}",
            command            => "/usr/bin/rsync -a --delete rsync://${thishost}/keystonefernetkeys/ /etc/keystone/fernet-keys/",
            interval           => {
            'start'    => 'OnCalendar',
            'interval' => "*-*-* ${sync_time}",
            },
            logging_enabled    => true,
            monitoring_enabled => false,
            user               => 'keystone',
        }
    }
}
