# Class publishing the Zuul repositories with git-daemon
class contint::zuul::git-daemon(
    $zuul_git_dir = '/var/lib/zuul/git'
) {

  package { 'git-daemon-sysvinit': ensure => present }

  # Point both git daemon paths to the same dir, this way we do not have a
  # /git/ prefix in the git:// URLs.
  $git_daemon_directory = $zuul_git_dir
  $git_daemon_base_path = $zuul_git_dir

  # We dont want to honor `git send-pack` commands so make sure the receive-pack
  # service is always disabled.
  $git_daemon_options = '--export-all --forbid-override=receive-pack'

  file { '/etc/default/git-daemon':
    mode    => '0444',
    owner   => 'root',
    group   => 'root',
    content => template('contint/default.git-daemon.erb'),
    require => Package['git-daemon-sysvinit'],
  }

  service { 'git-daemon':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    subscribe  => File['/etc/default/git-daemon'],
    require    => Package['git-daemon-sysvinit'],
  }

}
