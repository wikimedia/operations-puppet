# = Class: role::elasticsearch::relforge
#
# This class sets up Elasticsearch for relevance forge.
#
class role::elasticsearch::relforge {
    include ::standard
    include ::profile::base::firewall
    include ::profile::elasticsearch::relforge

    system::role { 'elasticsearch::relforge':
        ensure      => 'present',
        description => 'elasticsearch relforge',
    }
}
