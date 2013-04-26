define ceph::bootstrap_key($type, $cluster='ceph') {
  $keyring = "/var/lib/ceph/bootstrap-${type}/${cluster}.keyring"

  file { "/var/lib/ceph/bootstrap-${type}":
    ensure  => directory,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
  }

  # ping-pong trickery to securely do permissions, puppet has no umask on exec
  file { $keyring:
    ensure  => present,
    mode    => '0600',
    owner   => 'root',
    group   => 'root',
    require => File["/var/lib/ceph/bootstrap-${type}"],
  }

  $caps = $type ? {
    'osd' => 'mon "allow command osd create ...; allow command osd crush set ...; allow command auth add * osd allow\ * mon allow\ rwx; allow command mon getmap"',
    'mds' => 'mon "allow command auth get-or-create * osd allow\ * mds allow mon allow\ rwx; allow command mon getmap"',
  }

  exec { "ceph bootstrap ${keyring}":
    command  => "/usr/bin/ceph \
                --cluster=${cluster} \
                auth get-or-create client.bootstrap-${type} \
                ${caps} \
                > ${keyring}",
    unless   => "/usr/bin/test -s ${keyring}",
    require  => File[$keyring],
  }
}
