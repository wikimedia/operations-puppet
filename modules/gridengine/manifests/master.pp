# gridengine/master.pp

class gridengine::master {
  class { 'gridengine':
	gridmaster => $fqdn,
  }

  package { "gridengine-master":
	ensure => latest,
  }

  class monitoring {
	file { "/usr/local/sbin/grid-ganglia-report":
	  mode => 0555,
	  source => "puppet:///files/gridengine/grid-ganglia-report",
	  ensure => present;
	}

	cron { "grid-ganglia-report":
	  command => "/usr/local/sbin/grid-ganglia-report",
	  user => root,
	  ensure => present,
	  require => File["/usr/local/sbin/grid-ganglia-report"];
	}
  }

  include monitoring
}
