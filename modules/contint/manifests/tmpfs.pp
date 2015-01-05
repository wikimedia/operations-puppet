# Use a small tmpfs disk to help soften I/O on the contint slaves.
# A typical use case is speeding up interaction with MediaWiki
# sqlite database files in Jenkins jobs.
define contint::tmpfs(
  $mount_point = '/var/lib/jenkins/tmpfs',
  $size = '512M',
  ) {

  # Setup tmpfs to write SQLite files to
  file { $mount_point:
    ensure  => directory,
    mode    => '0755',
  }

  mount { $mount_point:
    ensure  => mounted,
    device  => 'tmpfs',
    fstype  => 'tmpfs',
    options => "noatime,defaults,size=${size},mode=1777",
    require => File[$mount_point],
  }

}
