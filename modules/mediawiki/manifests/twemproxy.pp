class mediawiki::twemproxy {
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
