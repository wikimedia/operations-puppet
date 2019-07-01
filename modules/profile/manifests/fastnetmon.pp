# == Class profile::fastnetmon
# Sets up Fastnetmon: netflow collector and DDoS detection
class profile::fastnetmon (
  Optional[Stdlib::HTTPUrl] $graphite_url = hiera('graphite_url', undef),
  ) {

    include network::constants

    $graphite_host = $graphite_url ? {
      undef   => undef,
      default => regsubst($graphite_url, 'http:\/\/(.*)$', '\1')
    }
    class { '::fastnetmon':
        networks      => $::network::constants::external_networks,
        graphite_host => $graphite_host
    }

    ferm::service { 'FNM-netflow':
        proto => 'udp',
        port  => '2055',
        desc  => 'FNM-netflow',
      srange  => '($NETWORK_INFRA $MGMT_NETWORKS)',
    }
}
