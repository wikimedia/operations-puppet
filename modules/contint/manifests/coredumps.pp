class contint::coredumps(
  $user  = 'jenkins',
  $group = 'jenkins',
  $coredir = '/var/lib/jenkins/coredumps',
) {

  file { $coredir:
    ensure  => directory,
    mode    => '0755',
    owner   => $user,
    group   => $group,
    require => [ User[$user], Group[$group] ],
  }

  sysctl::parameters { 'core_pattern':
    values => {
      'kernel.core_pattern' => "${coredir}/%t-%e-%s-%u-%p",
    }
  }

  cron { 'contint cleanup old coredumps':
    command => "find ${coredir} -type f -mtime +7 -exec rm {} \\;",
    user    => 'root',
    hour    => 1,
  }
}
