define ceph::key(
    $keyring,
    $caps,
    $cluster='ceph',
    $owner='root',
    $group='root',
    $mode='0600',
) {
    # ping-pong trickery to securely do permissions, puppet has no umask on exec
    file { $keyring:
        ensure  => present,
        mode    => '0600',
        owner   => 'root',
        group   => 'root',
    }

    exec { "ceph key ${name}":
        command  => "/usr/bin/ceph \
                    --cluster=${cluster} \
                    auth get-or-create client.${name} \
                    ${caps} \
                    > ${keyring}",
        unless   => "/usr/bin/test -s ${keyring}",
        require  => File[$keyring],
    }
}
