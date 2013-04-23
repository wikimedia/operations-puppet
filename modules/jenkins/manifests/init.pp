class jenkins {
  require jenkins::user

  # Upgrades are usually done manually by upload the Jenkins
  # package at apt.wikimedia.org then restarting jenkins and
  # double checking everything went fine.
  package { 'jenkins': ensure => present; }

  # Graphiz is needed by the job dependency graph plugin
  package { 'graphviz': ensure => present; }

  # Jenkins should write everything group writable so admins can interact with
  # files easily, hence we need it to run with umask 0002.
  # The Jenkins software is daemonized in the init script using /usr/bin/daemon
  # which reset the umask value.  Daemon accepts per user configuration via the
  # ~/.daemonrc, set the umask there.
  file { '/var/lib/jenkins/.daemonrc':
    ensure  => 'present',
    content => "jenkins umask=0002\n",
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0644',
  }

  service { 'jenkins':
    ensure     => 'running',
    enable     => true,
    hasrestart => true,
    # Better have umask properly set before starting
    require    => File['/var/lib/jenkins/.daemonrc'],
  }

  # nagios monitoring
  monitor_service { 'jenkins':
    description   => 'jenkins_service_running',
    check_command => 'nrpe_check_jenkins'
  }

  file { '/var/lib/jenkins':
    ensure => directory,
    mode   => '2775',  # group sticky bit
    owner  => 'jenkins',
    group  => 'jenkins',
  }
  # Top level jobs folder
  file { '/var/lib/jenkins/jobs':
    ensure => directory,
    mode   => '2775',  # group sticky bit
    owner  => 'jenkins',
    group  => 'jenkins',
  }
  file { '/etc/default/jenkins':
    owner  => 'root',
    group  => 'root',
    mode   => '0444',
    source => 'puppet:///modules/jenkins/etc_default_jenkins',
  }

}
