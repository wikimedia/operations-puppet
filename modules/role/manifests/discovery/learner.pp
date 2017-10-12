# = Class: role::discovery::learner
#
# This class sets up R and Python packages for machine learning, including with
# deep neural networks.
#
# Due to the outdated version of R on the currently available Ubuntu version
# (Trusty), it is recommended to only apply this role to instances running on
# Debian (Stretch or newer).
#
# filtertags: labs-project-discovery-stats
class role::discovery::learner {
    # include ::standard
    # include ::base::firewall
    include ::profile::discovery_computing::machine_learning
    include ::profile::discovery_computing::deep_learning

    system::role { 'role::discovery::learner':
        ensure      => 'present',
        description => 'Machine learning for Discovery Analysts',
    }

}
