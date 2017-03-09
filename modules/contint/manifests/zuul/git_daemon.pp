# Class publishing the Zuul repositories with git-daemon
class contint::zuul::git_daemon(
    $zuul_git_dir = '/var/lib/zuul/git'
) {
  # Point both git daemon paths to the same dir, this way we do not have a
  # /git/ prefix in the git:// URLs.
  $directory = $zuul_git_dir
  $base_path = $zuul_git_dir

  # Additional options passed to the Daemon.
  #
  # We dont want to honor `git send-pack` commands so make sure the receive-pack
  # service is always disabled.
  $daemon_options = '--export-all --forbid-override=receive-pack'

  user { 'gitdaemon':
    system =>  true,
  }

  systemd::syslog { 'git-daemon':
      base_dir    => '/var/lib/log',
      owner       => 'gitdaemon',
      group       => 'gitdaemon',
      readable_by => 'all',
  }

  base::service_unit { 'git-daemon':
    ensure  => present,
    systemd => true,
    require =>  User['gitdaemon'],
  }

}
