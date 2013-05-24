class mediawiki::twemproxy {
  package { 'twemproxy':
    ensure => latest;
  }

  upstart_job { "twemproxy": install => "true" }

  service { twemproxy:
    require => [ Package[twemproxy], Upstart_job[twemproxy] ],
    provider => upstart,
    ensure => running;
  }
}
