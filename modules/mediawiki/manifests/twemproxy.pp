class mediawiki::twemproxy {
  if $hostname =~ /^mw1063/ {
    class { 'twemproxy':
      config_file => '/a/common/wmf-config/twemproxy-eqiad.yaml',
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
