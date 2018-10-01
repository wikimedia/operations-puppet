# sets upt APT repository for labs openstack

# class default kept here until components not yet moved to profiles
# for parameterization are completed in modules/openstack

class openstack::cloudrepo(
    $version='mitaka',
) {

    if ($::lsbdistcodename == 'trusty') {

        if ($version != 'mitaka' and $version != 'liberty') {
            fail('Openstack versions > mitaka are not available on Trusty.')
        }

        if !defined(Apt::Repository['ubuntucloud']) {
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
        }
    } elsif os_version('debian jessie') and ($version == 'mitaka') {
        file{'/etc/apt/preferences.d/openstack.pref':
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            source => 'puppet:///modules/openstack/backports/openstack.pref',
        }
    } elsif os_version('debian stretch') and ($version == 'newton') {
        notify {'On stretch this will probably install Newton-versioned packages, but nothing is explicitly pinned':}
    } elsif os_version('debian stretch') and ($version == 'ocata') {
        notify {'On stretch this will probably install Ocata-versioned packages, but nothing is explicitly pinned':}
    } else {
        fail('This is an unknown combination of OpenStack and OS version')
    }
}
