# = Class: role::elasticsearch::relforge
#
# This class sets up Elasticsearch for relevance forge.
#
class role::elasticsearch::relforge {
    include ::profile::base::production
    include ::profile::base::firewall
    include ::profile::elasticsearch::relforge
    include ::profile::kibana

    system::role { 'elasticsearch::relforge':
        ensure      => 'present',
        description => 'elasticsearch relforge',
    }
}
