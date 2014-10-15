# = Class; graphite::labs::archiver
#
# Sets up a script to archive metrics from killed labs instances
class graphite::labs::archiver {
    file { '/usr/local/bin/archive-instances.py':
        source => 'puppet:///modules/graphite/archive-instances',
        owner  => '_graphite',
        group  => '_graphite',
        mode   => '0700',
    }
}
