# = Class: role::discovery::allstar_cruncher
#
# This class sets up R and Python packages for number crunching, statistical
# computing, forecasting, Bayesian inference, and machine learning. Once it's
# up and running: get your game on, go play.
#
# Due to the outdated version of R on the currently available Ubuntu version
# (Trusty), it is recommended to only apply this profile (and any profiles or
# roles that include it) to instances running on Debian (Stretch or newer).
#
# filtertags: labs-project-discovery-stats
class role::discovery::allstar_cruncher {
    # include ::standard
    # include ::base::firewall
    include ::profile::discovery_computing::forecasting
    # ^ includes ::profile::discovery_computing::bayesian_statistics
    include ::profile::discovery_computing::machine_learning

    system::role { 'role::discovery::allstar_cruncher':
        ensure      => 'present',
        description => 'Multi-purpose computing for Discovery Analysts',
    }

}
