class jenkins {
  require jenkins::user
  require jenkins::group

  # Upgrades are usually done manually by upload the Jenkins
  # package at apt.wikimedia.org then restarting jenkins and
  # double checking everything went fine.
  package { 'jenkins': ensure => present; }

  # Graphiz is needed by the job dependency graph plugin
  package { 'graphviz': ensure => present; }

  service { 'jenkins':
    ensure     => 'running',
    enable     => true,
    hasrestart => true,
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
