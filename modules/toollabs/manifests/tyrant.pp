# Class: toollabs::tyrant
#
# This role sets up a node as an UWSGI tyrant
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::tyrant($gridmaster) inherits toollabs {
    include toollabs::infrastructure,
        toollabs::exec_environ
    class { 'gridengine::submit_host':
        gridmaster => $gridmaster,
    }

    file { "${store}/submithost-${fqdn}":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File[$store],
        content => "${ipaddress}\n",
    }
}

