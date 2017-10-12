# = Class: role::discovery::deep_learner
#
# This class sets up R and Python packages for machine learning with deep
# neural networks.
#
# Due to the outdated version of R on the currently available Ubuntu version
# (Trusty), it is recommended to only apply this role to instances running on
# Debian (Stretch or newer).
#
# filtertags: labs-project-discovery-stats
class role::discovery::deep_learner {
    # include ::standard
    # include ::base::firewall
    include ::profile::discovery_computing::deep_learning

    system::role { 'role::discovery::deep_learner':
        ensure      => 'present',
        description => 'Deep learning for Discovery Analysts',
    }

}
