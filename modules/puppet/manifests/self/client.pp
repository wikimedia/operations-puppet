# == Class puppet::self::client
# Sets up a node as a puppet client with
# $server as the puppetmaster.
#
# == Parameters
# $server - hostname of the puppetmaster.
#
class puppet::self::client($server) {
    system::role { 'puppetclient':
        description => "Puppet client of ${server}"
    }

    # Most of the defaults in puppet::self::config
    # are good for setting up a puppet client.
    class { 'puppet::self::config':
        server => $server,
    }
}
