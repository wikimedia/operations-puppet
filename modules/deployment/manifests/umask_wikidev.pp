# == Class: deployment::umask_wikidev
#
# Set umask for wikidev users so that newly-created files are g+w
class deployment::umask_wikidev {
    file { '/etc/profile.d/umask-wikidev.sh':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/deployment/umask-wikidev-profile-d.sh',
    }
}
