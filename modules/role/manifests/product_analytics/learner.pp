# = Class: role::discovery::learner
#
# This class sets up R and Python packages for machine learning.
#
class role::product_analytics::learner {
    # include ::profile::base::production
    # include ::profile::base::firewall
    include ::profile::product_analytics::machine_learning

    system::role { 'role::product_analytics::learner':
        ensure      => 'present',
        description => 'VM configured for machine learning',
    }

}
