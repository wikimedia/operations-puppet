# set up a Tor relay (https://www.torproject.org/)
class role::tor_relay {
    include ::standard
    include ::profile::base::firewall
    include ::profile::tor::relay

    system::role { 'tor_relay':
        description => 'Tor relay'
    }

    rsync::quickdatacopy { 'var-lib-tor':
      ensure      => present,
      auto_sync   => false,
      source_host => 'radium.wikimedia.org',
      dest_host   => 'torrelay1001.wikimedia.org',
      module_path => '/var/lib/tor',
    }
}
