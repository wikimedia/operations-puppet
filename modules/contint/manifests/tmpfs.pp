# Use a small tmpfs disk to help soften I/O on the contint slaves.
# A typical use case is speeding up interaction with MediaWiki
# sqlite database files in Jenkins jobs.
define contint::tmpfs(
  Stdlib::Unixpath $mount_point = '/var/lib/jenkins/tmpfs',
  String $size = '512M',
  ) {

  # Setup tmpfs to write SQLite files to
  file { $mount_point:
    ensure  => directory,
    # user/group/mode set by mount
  }

  mount { $mount_point:
    ensure  => mounted,
    device  => 'none',
    fstype  => 'tmpfs',
    options => "noatime,defaults,size=${size},mode=1777",
    require => File[$mount_point],
  }

}
