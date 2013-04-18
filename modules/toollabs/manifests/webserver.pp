# Class: toollabs::webserver
#
# This role sets up a webserver in the Tool Labs model.
#
# Parameters:
#       gridmaster => FQDN of the gridengine master
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::webserver($gridmaster) {
	include toollabs
	include toollabs::exec_envrion
	class { 'gridengine::submit_host':
		gridmaster => $gridmaster,
	}

	package { [
			'libapache2-mod-suphp',
			'libhtml-parser-perl',
			'libwww-perl',
			'liburi-perl',
			'libdbd-sqlite3-perl' ]:
		ensure => present
	}

# TODO: Apache config
# TODO: Local scripts
# TODO: sshd config
}

