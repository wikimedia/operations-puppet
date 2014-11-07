class openstack::repo(
    $openstack_version=$::openstack::version,
) {
    apt::repository { 'ubuntucloud':
        uri        => 'http://ubuntu-cloud.archive.canonical.com/ubuntu',
        dist       => "precise-updates/${openstack_version}",
        components => 'main',
        keyfile    => 'puppet:///files/misc/ubuntu-cloud.key';
    }
}
