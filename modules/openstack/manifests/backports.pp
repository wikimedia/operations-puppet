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

    requires_os('debian == jessie')

    file{'/etc/apt/preferences.d/openstack.pref':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/openstack/backports/openstack.pref',
    }

    apt::conf{'backports-default-release':
        key      => 'APT::Default-Release',
        value    => 'jessie-backports',
        priority => '00',
        require  => File['/etc/apt/preferences.d/openstack.pref'],
    }
}
