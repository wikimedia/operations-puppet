define ceph::bootstrap_key($type, $cluster='ceph') {
    $keyring = "/var/lib/ceph/bootstrap-${type}/${cluster}.keyring"

    $caps = $type ? {
        'osd' => 'mon "allow command osd create ...; allow command osd crush set ...; allow command auth add * osd allow\ * mon allow\ rwx; allow command mon getmap"',
        'mds' => 'mon "allow command auth get-or-create * osd allow\ * mds allow mon allow\ rwx; allow command mon getmap"',
    }

    file { "/var/lib/ceph/bootstrap-${type}":
        ensure => directory,
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
    }

    ceph::key { "bootstrap-${type}":
        cluster => $cluster,
        keyring => $keyring,
        caps    => $caps,
        require => File["/var/lib/ceph/bootstrap-${type}"],
    }
}
