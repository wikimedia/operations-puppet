class openstack::repo(
    $openstack_version=$::openstack::version,
) {

    if ($::lsbdistcodename == 'precise') {
        apt::repository { 'ubuntucloud':
            uri        => 'http://ubuntu-cloud.archive.canonical.com/ubuntu',
            dist       => "precise-updates/${openstack_version}",
            components => 'main',
            keyfile    => 'puppet:///files/misc/ubuntu-cloud.key';
        }
    }
    if ($::lsbdistcodename == 'trusty') {
        # Icehouse is the default on trusty, no need to use the cloud archive.
        if (${openstack_version} != 'icehouse')
        {
            apt::repository { 'ubuntucloud':
                uri        => 'http://ubuntu-cloud.archive.canonical.com/ubuntu',
                dist       => "trusty-updates/${openstack_version}",
                components => 'main',
                keyfile    => 'puppet:///files/misc/ubuntu-cloud.key';
            }
        }
    }
}
