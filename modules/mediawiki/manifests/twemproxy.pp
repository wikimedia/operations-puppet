class mediawiki::twemproxy {
  if $hostname =~ /^mw1063/ {
    class { '::twemproxy':
        default_file => 'puppet:///modules/mediawiki/twemproxy.default',
    }
  } else {
    package { 'twemproxy':
      ensure => latest;
    }

    generic::upstart_job { "twemproxy": install => "true", start => "true" }

    service { twemproxy:
      require => [ Package[twemproxy], Generic::Upstart_job[twemproxy] ],
      provider => upstart,
      ensure => running;
    }
  }
}
