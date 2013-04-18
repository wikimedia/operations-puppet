# Class: toollabs::webserver
#
# This role sets up a webserver in the Tool Labs model.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::webserver {
    include gridengine::submit_host
    include toollabs::exec_envrion

    package { [
	'libapache2-mod-suphp',
	'libhtml-parser-perl',
	'libwww-perl',
	'liburi-perl',
	'libdbd-sqlite3-perl'
    ]:
	    ensure => present
    }
}

