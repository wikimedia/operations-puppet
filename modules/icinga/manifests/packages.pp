# = Class: icinga::packages
#
# Setup packages required to run icinga.
class icinga::packages {

    package { [
        'icinga',
        'icinga-doc',
    ] :
        ensure => latest,
    }

    # FIXME: Unsure why this is required
    file { '/etc/init.d/icinga':
        source => 'puppet:///modules/icinga/icinga-init',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
}
