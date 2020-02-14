# https://noc.wikimedia.org/
class profile::noc {

    include profile::mediawiki::common

    ferm::service { 'noc-http':
        proto  => 'tcp',
        port   => 'http',
        srange => '($CACHES $CUMIN_MASTERS)',
    }

    class { '::noc': }
}
