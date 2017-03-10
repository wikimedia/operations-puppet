# = Class: role::elasticsearch::relforge
#
# This class sets up Elasticsearch for relevance forge.
#
class role::elasticsearch::relforge {

    include ::profile::elasticsearch::common

    include ::elasticsearch::nagios::check

    # the relforge cluster is serving labs, it should never be connected from
    # production, except from terbium to import production indices.
    ::ferm::service { 'elastic-https-terbium':
      ensure => present,
      proto  => 'tcp',
      port   => '9243',
      srange => '@resolve(terbium.eqiad.wmnet)',
    }

}
