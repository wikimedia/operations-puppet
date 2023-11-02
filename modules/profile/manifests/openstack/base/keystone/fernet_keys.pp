class profile::openstack::base::keystone::fernet_keys(
    Array[Stdlib::Fqdn] $keystone_hosts = lookup('profile::openstack::base::openstack_controllers'),
    ) {

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
        read_only   => 'yes',
    }

    # It's important to do these steps in the right order: a host should rotate its keys, and immediately
    #  after that each other host should rsync to pick up the changes.
    # Rotations happen on the hour, and syncing on the half.
    #
    # Note that if the order of hosts in $keystone_hosts is not consistent across all
    #  hosts this will cause chaos.
    #
    $hostcount = count($keystone_hosts)
    $staggerhours = 24/$hostcount

    $keystone_hosts.each |$index, Stdlib::Fqdn $fqdn| {
        $activehour = $index * $staggerhours
        $is_this_host = $::facts['networking']['hostname'] == $fqdn.split('\.')[0]

        systemd::timer::job { "keystone_sync_keys_from_${fqdn}":
            ensure             => $is_this_host.bool2str('absent', 'present'),
            description        => "Sync keys for Keystone fernet tokens to ${fqdn}",
            command            => "/usr/bin/rsync -a --delete rsync://${fqdn}/keystonefernetkeys/ /etc/keystone/fernet-keys/",
            interval           => {
            'start'    => 'OnCalendar',
            'interval' => "*-*-* ${activehour}:30:00",
            },
            logging_enabled    => true,
            monitoring_enabled => false,
            user               => 'keystone',
        }

        if $is_this_host {
            systemd::timer::job { 'keystone_rotate_keys':
                description        => 'Rotate keys for Keystone fernet tokens',
                command            => '/usr/bin/keystone-manage fernet_rotate --keystone-user keystone --keystone-group keystone',
                interval           => {
                    'start'    => 'OnCalendar',
                    'interval' => "*-*-* ${activehour}:00:00",
                },
                logging_enabled    => true,
                user               => 'root',
                monitoring_enabled => false,
            }
        }
    }
}
