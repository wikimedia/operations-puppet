# == Class: role::graphite::production
#
# Set up graphite instance for production.
# Also includes icinga checks for anomalies for Mediawiki, EL & Swift metrics
# Instance requires people to authenticate via LDAP before they can see metrics.
#
class role::graphite::production {
    class { 'role::graphite::base':
        storage_dir      => '/var/lib/carbon',
        auth             => true,
        c_relay_settings => {
          backends => [
            'graphite1001.eqiad.wmnet:1903',
            'graphite2001.codfw.wmnet:1903',
          ],
        }
    }

    ferm::service { 'carbon_c_relay-local_relay_udp':
        proto   => 'udp',
        port    => '1903',
        srange  => '@resolve((graphite1001.eqiad.wmnet graphite2001.codfw.wmnet))',
    }

    ferm::service { 'carbon_c_relay-local_relay_tcp':
        proto   => 'tcp',
        port    => '1903',
        srange  => '@resolve((graphite1001.eqiad.wmnet graphite2001.codfw.wmnet))',
    }
}

