class apt::unattendedupgrades($ensure=present) {
	package { [ 'unattended-upgrades', 'update-notifier-common' ]:
		ensure => $ensure,
	}

	apt::conf { 'auto-upgrades':
		ensure   => $ensure,
		priority => '20',
		key      => 'APT::Periodic::Unattended-Upgrade',
		value    => '1',
	}
}
