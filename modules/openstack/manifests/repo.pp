class openstack::repo(
    $openstack_version=$::openstack::version,
) {
    # As of 26/10/2015 we support kilo on trusty (lsb_release -c)
    if ($::lsbdistcodename == 'trusty') {
        apt::repository { 'ubuntucloud':
            uri        => 'http://ubuntu-cloud.archive.canonical.com/ubuntu',
            dist       => "trusty-updates/${openstack_version}",
            components => 'main',
            keyfile    => 'puppet:///files/misc/ubuntu-cloud.key';
        }
    }
}
