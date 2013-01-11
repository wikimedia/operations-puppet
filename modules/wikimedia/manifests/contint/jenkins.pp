# vim: ts=2 sw=2 expandtab
class wikimedia::contint::jenkins {

  require packages
  require webserver

  package { 'jenkins':
    ensure => present
  }

  # Graphiz needed by the plugin that does the projects dependencies graph
  package { 'graphviz':
    ensure => present
  }

  # Get several OpenJDK packages including the jdk.
  # (openjdk is the default distribution for the java define.
  # The java define is found in modules/java/manifests/init.pp )
  java { 'java-6-openjdk': version => 6, alternative => true  }
  java { 'java-7-openjdk': version => 7, alternative => false }

  service { 'jenkins':
    ensure     => 'running',
    enable     => true,
    hasrestart => true,
    start      => '/etc/init.d/jenkins start',
    stop       => '/etc/init.d/jenkins stop';
  }

  require ::groups::jenkins
  user { 'jenkins':
    name       => 'jenkins',
    home       => '/var/lib/jenkins',
    shell      => '/bin/bash',
    gid        => 'jenkins',
    system     => true,
    managehome => false,
    require    => Group['jenkins'];
  }

  file { '/var/lib/jenkins/.gitconfig':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0444',
    source  => 'puppet:///modules/wikimedia/contint/gitconfig-jenkins',
    require => User['jenkins'];
  }

  # Setup tmpfs to write SQLite files to
  file { '/var/lib/jenkins/tmpfs':
    ensure  => directory,
    mode    => '0755',
    owner   => jenkins,
    group   => jenkins,
    require => [ User['jenkins'], Group['jenkins'] ];
  }

  mount { '/var/lib/jenkins/tmpfs':
    ensure  => mounted,
    device  => 'tmpfs',
    fstype  => 'tmpfs',
    options => 'noatime,defaults,size=512M,mode=755,uid=jenkins,gid=jenkins',
    require => [
      User['jenkins'],
      Group['jenkins'],
      File['/var/lib/jenkins/tmpfs'],
    ];
  }

  # nagios monitoring
  monitor_service { 'jenkins':
    description   => 'jenkins_service_running',
    check_command => 'check_procs_generic!1!3!1!20!jenkins'
  }

  file {
    '/var/lib/jenkins':
      ensure => directory,
      mode   => '2775',  # group sticky bit
      owner  => 'jenkins',
      group  => 'jenkins';
    '/var/lib/jenkins/.git':
      ensure => directory,
      mode   => '2775',  # group sticky bit
      group  => 'jenkins';
    # Top level jobs folder
    '/var/lib/jenkins/jobs/':
      ensure => directory,
      mode   => '2775',  # group sticky bit
      owner  => 'jenkins',
      group  => 'jenkins';
    '/var/lib/jenkins/bin':
      ensure => directory,
      owner  => 'jenkins',
      group  => 'wikidev',
      mode   => '0775';
  }

  # Jobs generated files that end up being publics (such as nightly builds)
  file {
    '/srv/org/mediawiki/integration/nightly.css':
      owner  => www-data,
      group  => wikidev,
      mode   => '0444',
      source => 'puppet:///modules/wikimedia/contint/docroot/nightly.css';
    '/srv/org/mediawiki/integration/WikipediaMobile':
      ensure => directory,
      owner  => jenkins,
      group  => wikidev,
      mode   => '0755';
    # Copy HTML materials for ./WikipediaMobile/nightly/ :
    '/srv/org/mediawiki/integration/WikipediaMobile/nightly':
      ensure  => directory,
      owner   => jenkins,
      group   => wikidev,
      mode    => '0644',
      source  => 'puppet:///modules/wikimedia/contint/docroot/WikipediaMobile',
      recurse => true;
    '/srv/org/mediawiki/integration/WiktionaryMobile':
      ensure => directory,
      owner  => jenkins,
      group  => wikidev,
      mode   => '0755';
    '/srv/org/mediawiki/integration/WiktionaryMobile/nightly':
      ensure  => directory,
      owner   => jenkins,
      group   => wikidev,
      mode    => '0644',
      source  => 'puppet:///modules/wikimedia/contint/docroot/WiktionaryMobile',
      recurse => true;
    '/srv/org/mediawiki/integration/WLMMobile':
      ensure => directory,
      owner  => jenkins,
      group  => wikidev,
      mode   => '0755';
    '/srv/org/mediawiki/integration/WLMMobile/nightly':
      ensure  => directory,
      owner   => jenkins,
      group   => wikidev,
      mode    => '0644',
      source  => 'puppet:///modules/wikimedia/contint/docroot/WLMMobile',
      recurse => true;
  }

  file {
    '/etc/default/jenkins':
      owner  => 'root',
      group  => 'root',
      mode   => '0444',
      source => 'puppet:///modules/wikimedia/contint/etc_default_jenkins';
  }
}
