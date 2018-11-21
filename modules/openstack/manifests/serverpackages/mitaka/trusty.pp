class openstack::serverpackages::mitaka::trusty(
) {
    # packages are installed from specific component profiles
    # only install repo here

    if !defined(Apt::Repository['ubuntucloud']) {
        apt::repository { 'ubuntucloud':
            uri        => 'http://ubuntu-cloud.archive.canonical.com/ubuntu',
            dist       => 'trusty-updates/mitaka',
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
}
