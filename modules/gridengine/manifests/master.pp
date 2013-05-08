# gridengine.pp


class gridengine::master {
	class { 'gridengine':
		gridmaster => $fqdn,
	}

  package { "gridengine-master":
    ensure => latest,
  }
}
