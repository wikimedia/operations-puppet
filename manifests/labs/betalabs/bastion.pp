class labs::betalabs::bastion {

	include misc::scripts

	# Unwanted packages:
	package { [
		  'ack'
		, 'irssi'
		]: ensure => absent
	}

	# Start with some tools used by sysadmins
	package { [
		  'ack-grep'
		, 'dsh'
		, 'joe'
		, 'tree'
		]: ensure => installed
	}

	file {
		'/usr/local/bin/ack':
			  ensure => link
			, target => '/usr/bin/ack-grep'
			, require => Package['ack-grep']
		;
	}

	# `sudo` policies are managed through the nova interface
}
