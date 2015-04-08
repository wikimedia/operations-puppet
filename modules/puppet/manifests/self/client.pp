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

    $puppet_certname = $::fqdn

    # Most of the defaults in puppet::self::config
    # are good for setting up a puppet client.
    #
    # We'd best be sure that our ldap config is set up properly
    # before puppet goes to work, though.
    class { 'puppet::self::config':
        server  => $server,
        certname => $puppet_certname,
        require => File['/etc/ldap/ldap.conf', '/etc/ldap.conf', '/etc/nslcd.conf'],
    }
}
