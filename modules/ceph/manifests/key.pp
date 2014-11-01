# Definition: ceph::key
#
# This class adds or removes a Ceph auth key and stores it in the filesystem.
#
# Parameters:
#    $keyring
#        Filename of the keyring file where the key will be stored.
#    $caps,
#        Capabilities that the auth key will have.
#    $cluster
#        Defaults to ceph. Name of the Ceph cluster.
#    $owner
#        Defaults to root. Owner username of the keyring file.
#    $group
#        Defaults to root. Owner groupname  of the keyring file.
#    $mode
#        Defaults to 0600. File mode in octal.
#    $ensure
#        Defaults to present.
#
# Actions:
#     Creates or deletes the key with "ceph auth"
#     Creates a keyring file with that key on the filesystem
#
# Requires:
#     Class[ceph]
#
# Sample Usage:
#     ceph::key { 'test':
#         ensure  => present,
#         cluster => 'ceph',
#         keyring => '/srv/myapp/ceph.key',
#         caps    => 'mon "allow r" osd "allow rwx"',
#     }

define ceph::key(
    $keyring,
    $caps,
    $cluster='ceph',
    $owner='root',
    $group='root',
    $mode='0600',
    $ensure='present',
) {
    # ping-pong trickery to securely do permissions, puppet has no umask on exec
    file { $keyring:
        ensure => $ensure,
        owner  => $owner,
        group  => $group,
        mode   => $mode,
        backup => false,
    }

    if $ensure == 'present' {
        exec { "ceph key ${name}":
            command => "/usr/bin/ceph --cluster=${cluster} \
                        auth get-or-create client.${name} \
                        ${caps} \
                        > ${keyring}",
            unless  => "/usr/bin/test -s ${keyring}",
            require => File[$keyring],
        }
    } elsif $ensure == 'absent' {
        exec { "ceph key ${name}":
            command => "/usr/bin/ceph --cluster=${cluster} \
                        auth del client.${name}",
            onlyif  => "/usr/bin/ceph auth print-key client.${name}",
        }
    } else {
        fail('ceph::key ensure parameter must be absent or present')
    }
}
