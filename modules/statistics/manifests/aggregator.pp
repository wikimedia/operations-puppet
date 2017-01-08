# == Class statistics::aggregator
# Handles projectcounts aggregation code
#
class statistics::aggregator {
    Class['::statistics'] -> Class['::statistics::aggregator']

    $working_path     = "${::statistics::working_path}/aggregator"

    $script_path      = "${working_path}/scripts"
    $user             = $::statistics::user::username
    $group            = $::statistics::user::username

    file { $working_path:
        ensure => 'directory',
        owner  => $user,
        group  => $group,
        mode   => '0755',
    }

    git::clone { 'aggregator_code':
        ensure    => 'latest',
        directory => $script_path,
        origin    => 'https://gerrit.wikimedia.org/r/p/analytics/aggregator.git',
        owner     => $user,
        group     => $group,
        mode      => '0755',
        require   => File[$working_path],
    }

}
