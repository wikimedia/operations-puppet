# == Class profile::fastnetmon
# Sets up Fastnetmon: netflow collector and DDoS detection
class profile::fastnetmon () {

    include network::constants

    ensure_resource('class', 'geoip')

    class { '::fastnetmon':
        networks      => $::network::constants::external_networks,
    }

    ferm::service { 'FNM-netflow':
        proto => 'udp',
        port  => '2055',
        desc  => 'FNM-netflow',
      srange  => '($NETWORK_INFRA $MGMT_NETWORKS)',
    }

    logrotate::rule { 'fastnetmon':
        ensure        => present,
        file_glob     => '/var/log/fastnetmon.log',
        frequency     => 'daily',
        copy_truncate => true,
        missing_ok    => true,
        compress      => true,
        not_if_empty  => true,
        rotate        => 15,
    }
}
