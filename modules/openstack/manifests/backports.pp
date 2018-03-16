# Jessie has Mitaka in backports (T169099)
# We want to install backports eligible packages
# and their dependencies (and the dependencies of
# those dependencies) from this source.
#
# This sets backports as the default source for
# packages and will resolve dependencies in tow.
# Packages from wikimedia sources will have a higher
# priority and will by default be chosen.

class openstack::backports {

    # Block out for now until puppet compiler facts can be updated
    # requires_os('debian == jessie')

    file{'/etc/apt/preferences.d/openstack.pref':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/openstack/backports/openstack.pref',
    }

    apt::conf{ 'backports-default-release':
        key      => 'APT::Default-Release',
        value    => 'jessie-backports',
        priority => '00',
        require  => File['/etc/apt/preferences.d/openstack.pref'],
        notify   => Exec['post-backports-apt-update'],
    }

    exec { 'post-backports-apt-update':
        command     => '/usr/bin/apt-get update',
        refreshonly => true,
        logoutput   => true,
        notify      => Exec['post-backports-apt-upgrade'],
    }

    exec { 'post-backports-apt-upgrade':
        command     => '/usr/bin/apt-get upgrade -y',
        refreshonly => true,
        logoutput   => true,
    }
}
