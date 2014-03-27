# == Class mediawiki::twemproxy
#
# Installs Twitter memcached proxy ensuring it is always the latest version
# and always running.
#
class mediawiki::twemproxy {
  package { 'twemproxy':
    ensure => latest,
  }

  generic::upstart_job { 'twemproxy':
      install => true,
      start   => true,
  }

  service { 'twemproxy':
    ensure   => running,
    provider => upstart,
    require  => [
        Package['twemproxy'],
        Generic::Upstart_job['twemproxy'],
    ],
  }
}
