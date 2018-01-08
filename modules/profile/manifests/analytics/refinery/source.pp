# == Class profile::analytics::refinery::source
# Clones analytics/refinery/source repo and keeps it up-to-date
#
class profile::analytics::refinery::source {
    $path = '/srv/refinery-source'

    file { $path:
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    git::clone { 'refinery_source':
        ensure    => 'latest',
        directory => $path,
        origin    => 'https://gerrit.wikimedia.org/r/p/analytics/refinery/source.git',
        owner     => 'root',
        group     => 'root',
        mode      => '0755',
        require   => File[$path],
    }
}
