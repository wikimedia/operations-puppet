# = Class: role::discovery::learner
#
# This class sets up R and Python packages for machine learning.
#
# filtertags: labs-project-discovery-stats
class role::product_analytics::learner {
    # include ::profile::standard
    # include ::profile::base::firewall
    include ::profile::product_analytics::machine_learning

    system::role { 'role::product_analytics::learner':
        ensure      => 'present',
        description => 'VM configured for machine learning',
    }

}
