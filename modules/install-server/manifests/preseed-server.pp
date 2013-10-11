# Class: install-server::preseed-server
#
# This class populated preseeding server's configuration
#
# Parameters:
#
# Actions:
#       Populate preseeding configuration directory
#
# Requires:
#
# Sample Usage:
#   include install-server::preseed-server

class install-server::preseed-server {
    file { '/srv/autoinstall':
        ensure  => directory,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/install-server/autoinstall',
        recurse => true,
        links   => manage
    }
}
