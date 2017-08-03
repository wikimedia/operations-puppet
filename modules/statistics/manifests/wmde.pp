# Licence AGPL version 3 or later
#
# Class for running WMDE releated statistics & analytics scripts.
#
# @author Addshore
class statistics::wmde(
    $statsd_host,
    $graphite_host,
    $wmde_secrets
) {

    # The statistics module needs to be loaded before this one
    Class['::statistics'] -> Class['::statistics::wmde']

    include ::statistics::wmde::user

    # Scripts & crons that generate data for graphite
    class { '::statistics::wmde::graphite':
        dir           => $statistics::wmde::user::homedir,
        user          => $statistics::wmde::user::username,
        statsd_host   => $statsd_host,
        graphite_host => $graphite_host,
        wmde_secrets  => $wmde_secrets
    }

}
