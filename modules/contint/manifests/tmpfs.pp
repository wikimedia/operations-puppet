# Wikimedia uses a small tmpfs disk to help soften I/O on the contint server.
# A typical use cases are the MediaWiki sqlite files
define contint::tmpfs(
  $user = 'jenkins',
  $group = 'jenkins',
  $mount_point = '/var/lib/jenkins/tmpfs',
  $size = '512M',
  ) {

  # Setup tmpfs to write SQLite files to
  file { $mount_point:
    ensure  => directory,
    mode    => '0755',
    owner   => $user,
    group   => $group,
    require => [ User[$user], Group[$group] ],
  }

  mount { $mount_point:
    ensure  => mounted,
    device  => 'tmpfs',
    fstype  => 'tmpfs',
    options => "noatime,defaults,size=${size},mode=755,uid=${user},gid=${group}",
    require => [ User[$user], Group[$group],
      File[$mount_point] ],
  }

}
