# https://noc.wikimedia.org/
class profile::noc {

    include profile::mediawiki::common

    # http from envoy to httpd on the backend itself
    ferm::service { 'noc-http-envoy':
        proto  => 'tcp',
        port   => 'http',
        srange => "(${::ipaddress} ${::ipaddress6}",
    }

    # http from cumin masters
    ferm::service { 'noc-http-cumin':
        proto  => 'tcp',
        port   => 'http',
        srange => '$CUMIN_MASTERS',
    }
    class { '::noc': }
}
