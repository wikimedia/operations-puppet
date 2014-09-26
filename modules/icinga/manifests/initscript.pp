# Class: icinga::initscript
#
# Sets up a custom init script for icinga
# FIXME: Unsure why this is required
class icinga::initscript {
    file { '/etc/init.d/icinga':
        source => 'puppet:///modules/icinga/icinga-init',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
}
