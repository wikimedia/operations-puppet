# == Class contint::website
#
# Class for website hosted on the continuous integration server
# https://integration.mediawiki.org/
# https://doc.wikimedia.org/
#
# === Parameters
#
# [*jenkins_agent_username*] Unix username the documentation jobs run as.
#
class contint::website(
    $jenkins_agent_username
) {

  # Need to send Vary: X-Forwarded-Proto since most sites are forced to HTTPS
  # and behind a varnish cache. See also T62822
  include ::apache::mod::headers
  include ::apache::mod::rewrite

  # Static files in these docroots are in integration/docroot.git

  file { '/srv/org':
    ensure => directory,
    mode   => '0775',
    owner  => $jenkins_agent_username,
    group  => $jenkins_agent_username,
  }

  file { '/srv/org/wikimedia':
    ensure => directory,
    mode   => '0775',
    owner  => $jenkins_agent_username,
    group  => $jenkins_agent_username,
  }
  file { '/srv/org/wikimedia/integration':
    ensure => directory,
    mode   => '0775',
    owner  => $jenkins_agent_username,
    group  => $jenkins_agent_username,
  }
  # MediaWiki code coverage
  file { '/srv/org/wikimedia/integration/coverage':
    ensure => directory,
    mode   => '0775',
    owner  => $jenkins_agent_username,
    group  => $jenkins_agent_username,
  }

  # Jenkins console logs
  file { '/srv/org/wikimedia/integration/logs':
    ensure => directory,
    mode   => '0775',
    owner  => $jenkins_agent_username,
    group  => $jenkins_agent_username,
  }

  # Apache configuration for integration.wikimedia.org
  apache::site { 'integration.wikimedia.org':
    content => template('contint/apache/integration.wikimedia.org.erb'),
  }

  # Apache configuration for integration.mediawiki.org
  apache::site { 'integration.mediawiki.org':
    content => template('contint/apache/integration.mediawiki.org.erb'),
  }

  # Written to by jenkins for automatically generated
  # documentations
  file { '/srv/org/wikimedia/doc':
    ensure => directory,
    mode   => '0775',
    owner  => $jenkins_agent_username,
    group  => $jenkins_agent_username,
  }

  # Apache configuration for doc.wikimedia.org
  apache::site { 'doc.wikimedia.org':
    content => template('contint/apache/doc.wikimedia.org.erb'),
  }

}
