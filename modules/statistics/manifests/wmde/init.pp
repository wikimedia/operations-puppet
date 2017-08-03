# Licence AGPL version 3 or later
#
# Class for running WMDE releated statistics & analytics scripts.
#
# @author Addshore
class statistics::wmde::init {

    # The statistics module needs to be loaded before this one
    Class['::statistics'] -> Class['::statistics::wmde::init']

    $statistics_working_path = $::statistics::working_path

    class { '::statistics::wmde::user':
        homedir => "${statistics_working_path}/analytics-wmde",
    }

    # Scripts & crons that generate data for graphite
    class { '::statistics::wmde::graphite':
        dir           => $statistics::wmde::user::homedir,
        user          => $statistics::wmde::user::username,
        statsd_host   => hiera('statsd'),
        # TODO graphite hostname should be in hiera
        graphite_host => 'graphite.eqiad.wmnet',
    }

}
