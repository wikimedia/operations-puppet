# Class publishing the Zuul repositories with git-daemon
class contint::zuul::git_daemon(
    Stdlib::Unixpath $zuul_git_dir = '/var/lib/zuul/git',
    Integer $max_connections = 32,
) {
  # Point both git daemon paths to the same directory. This way we do not have
  # a /git/ prefix in the git:// URLs.

  # Base path is the git root, similar to Apache DocumentRoot
  $base_path = $zuul_git_dir

  # The actual directory to serve
  $directory = $zuul_git_dir

  # Additional options passed to the Daemon.
  #
  # We dont want to honor `git send-pack` commands so make sure the receive-pack
  # service is always disabled. Default is to allow 32 connections.
  $daemon_options = "--export-all --forbid-override=receive-pack --max-connections=${max_connections}"

  user { 'gitdaemon':
    system => true,
    gid    => 'nogroup',
    home   => '/nonexistent',  # like "nobody"
  }

  systemd::syslog { 'git-daemon':
      owner       => 'gitdaemon',
      group       => 'nogroup',
      readable_by => 'all',
  }

  systemd::service { 'git-daemon':
      ensure  => present,
      content => systemd_template('git-daemon'),
      restart => true,
      require => User['gitdaemon'],
  }

}
