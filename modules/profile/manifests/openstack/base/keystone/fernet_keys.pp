# SPDX-License-Identifier: Apache-2.0
class profile::openstack::base::keystone::fernet_keys(
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::base::openstack_control_nodes'),
    String $cred_key_0 = lookup('profile::openstack::base::keystone::credential_key_0'),
    String $cred_key_1 = lookup('profile::openstack::base::keystone::credential_key_1'),
) {
    file { '/etc/keystone/fernet-keys':
        ensure => directory,
        owner  => 'keystone',
        group  => 'keystone',
        mode   => '0770',
    }

    rsync::server::module { 'keystonefernetkeys':
        path          => '/etc/keystone/fernet-keys',
        uid           => 'keystone',
        gid           => 'keystone',
        hosts_allow   => $openstack_control_nodes.map |$node| { $node['cloud_private_fqdn'] },
        auto_firewall => true,
        read_only     => 'yes',
    }

    # It's important to do these steps in the right order: a host should rotate its keys, and immediately
    #  after that each other host should rsync to pick up the changes.
    # Rotations happen on the hour, and syncing on the half.
    #
    # Note that if the order of hosts in $keystone_hosts is not consistent across all
    #  hosts this will cause chaos.
    #
    $hostcount = count($openstack_control_nodes)
    $staggerhours = 24/$hostcount

    $openstack_control_nodes.each |$index, OpenStack::ControlNode $node| {
        $activehour = $index * $staggerhours
        $is_this_host = $::facts['networking']['fqdn'] == $node['host_fqdn']
        $fqdn = $node['cloud_private_fqdn']

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

    # Credential keys
    #
    #  These don't need to rotate but we do need to call credential_migrate
    #  any time they change.
    #
    #  See https://docs.openstack.org/keystone/zed/admin/credential-encryption.html
    file { '/etc/keystone/credential-keys':
        ensure => directory,
        owner  => 'keystone',
        group  => 'keystone',
        mode   => '0700',
    }

    file { '/etc/keystone/credential-keys/credential-key-0':
        ensure  => directory,
        owner   => 'keystone',
        group   => 'keystone',
        mode    => '0400',
        content => $cred_key_0,
    }

    # Strictly speaking this key isn't needed but keystone-manage
    #  creates it so I'm installing it to avoid future confusion
    file { '/etc/keystone/credential-keys/credential-key-1':
        ensure  => directory,
        owner   => 'keystone',
        group   => 'keystone',
        mode    => '0400',
        content => $cred_key_1,
    }

    exec { 'migrate_credential_keys':
        command     => '/usr/bin/keystone-manage credential_migrate --keystone-user keystone --keystone-group keystone',
        subscribe   => [File['/etc/keystone/credential-keys/credential-key-0'],
                        File['/etc/keystone/credential-keys/credential-key-1']],
        refreshonly => true,
    }
}
