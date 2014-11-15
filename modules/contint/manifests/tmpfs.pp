# Use a small tmpfs disk to help soften I/O on the contint slaves.
# A typical use case is speeding up interaction with MediaWiki
# sqlite database files in Jenkins jobs.
define contint::tmpfs(
  $user = 'jenkins',
  $group = 'jenkins',
  $mount_point = '/var/lib/jenkins/tmpfs',
  $size = '512M',
  ) {

  file { $mount_point:
    ensure  => directory,
    mode    => '0755',
    owner   => $user,
    group   => $group,
  }

  mount { $mount_point:
    ensure  => mounted,
    device  => 'tmpfs',
    fstype  => 'tmpfs',
    options => "noatime,defaults,size=${size},mode=755,uid=${user},gid=${group}",
    require => File[$mount_point],
  }

}
