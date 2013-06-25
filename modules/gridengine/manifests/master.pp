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
	  source => "puppet:///modules/gridengine/grid-ganglia-report",
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

  cron { "push-accounting-to-shared":
    command => "cp -f /var/lib/gridengine/default/common/accounting /data/project/.system/accounting.tmp && mv -f /data/project/.system/accounting.tmp /data/project/.system/accounting",
    user => root,
    minute => [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55],
    ensure => present;
  }
}
