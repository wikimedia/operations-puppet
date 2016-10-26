# Convenience class to avoid dependency hell.
#
# Creates a directory used on the contint master
class contint::master_dir() {
    # The name is not smart, but please forgive me for now...
    file { '/srv/ssd':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
    }
}
