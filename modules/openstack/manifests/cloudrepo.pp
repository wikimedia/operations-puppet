# sets upt APT repository for labs openstack

# class default kept here until components not yet moved to profiles
# for parameterization are completed in modules/openstack

class openstack::cloudrepo(
    $version='mitaka',
) {

    # As of 26/10/2015 we support kilo on trusty (lsb_release -c)
    if ($::lsbdistcodename == 'trusty') {
        apt::repository { 'ubuntucloud':
            uri        => 'http://ubuntu-cloud.archive.canonical.com/ubuntu',
            dist       => "trusty-updates/${version}",
            components => 'main',
            keyfile    => 'puppet:///modules/openstack/cloudrepo/ubuntu-cloud.key',
            notify     => Exec['apt_key_and_update'];
        }

        # First installs can trip without this
        # seeing the mid-run repo as untrusted
        exec {'apt_key_and_update':
            command     => '/usr/bin/apt-key update && /usr/bin/apt-get update',
            refreshonly => true,
            logoutput   => true,
        }

    } elsif os_version('debian jessie') and ($version == 'mitaka') {
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
    } elsif os_version('debian stretch') and ($version == 'ocata') {
        notify {'On stretch this will probably install Ocata-versioned packages, but nothing is explicitly pinned':}
    } else {
        fail('This is an unknown combination of OpenStack and OS version')
    }
}
