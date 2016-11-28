# = Class: role::elasticsearch::relforge
#
# This class sets up Elasticsearch for relevance forge.
#
class role::elasticsearch::relforge {

    class { '::role::elasticsearch::common':
        ferm_srange => '$LABS_NETWORKS',
    }
    include ::elasticsearch::nagios::check

    # the relforge cluster is serving labs, it should never be connected from
    # production, except from terbium to import production indices.
    ::ferm::service { 'elastic-https':
      ensure => present,
      proto  => 'tcp',
      port   => '9243',
      srange => '@resolve(terbium.eqiad.wmnet)',
    }

}
