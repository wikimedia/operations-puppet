# == Class role::analytics_cluster::refinery::source
# Clones analytics/refinery/source repo and keeps it up-to-date
#
class role::analytics_cluster::refinery::source {
    require ::statistics

    $path = "${::statistics::working_path}/refinery-source"

    $user = $::statistics::user::username
    $group = $user

    file { $path:
        ensure => 'directory',
        owner  => $user,
        group  => $group,
        mode   => '0755',
    }

    git::clone { 'refinery_source':
        ensure    => 'latest',
        directory => $path,
        origin    => 'https://gerrit.wikimedia.org/r/p/analytics/refinery/source.git',
        owner     => $user,
        group     => $group,
        mode      => '0755',
        require   => File[$path],
    }
}
