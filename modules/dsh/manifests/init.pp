# == Class dsh
#
# Standard installation of dsh (Dancer's distributed shell)
#
# Also sets up all groups from modules/dsh/files/group
class dsh {
    package { 'dsh':
        ensure => present,
    }

    include dsh::config
    dsh::group { 'mediawiki-installation': }
}
