# Class: install_server::preseed_server
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
#   include install_server::preseed_server

class install_server::preseed_server {
    file { '/srv/autoinstall':
        ensure  => directory,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/install_server/autoinstall',
        recurse => true,
        links   => manage,
        purge   => true,
    }
}
