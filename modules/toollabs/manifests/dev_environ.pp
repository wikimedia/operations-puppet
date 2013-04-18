# Class: toollabs::dev_environ
#
# This class sets up a node as a dev environment for tool labs.
# This is a "sub" role included by the actual tool labs roles and would
# normally not be included directly in node definitions.
#
# Those are the dependencies for development tools and packages intended
# for interactive use.
#
# Parameters:
#
# Actions:
#   - Install tool dependencies
#
# Requires:
#
# Sample Usage:
#
class toollabs::dev_environ {
    include toollabs

    package { [
	'libtool',
	'autoconf',
	'sqlite3',
	'python-dev',
	'libmysqlclient-dev',
	'cython'
    ]:
	    ensure => present
    }

# TODO: deploy scripts
# TODO: packager
}
