# This class holds all the apt pinning for key packages in the Toolforge

class toollabs::apt_pinning {

    #
    # linux kernel
    #
    $linux_pkg = $facts['os_version'] ? {
        'trusty'  => 'linux-image-generic',
        'jessie'  => 'linux-meta',
        'stretch' => 'linux-image-amd64',
    }

    $linux_pkg_version = $facts['os_version'] ? {
        'trusty'  => 'version 3.13.0.141.151',
        'jessie'  => 'version 1.16',
        'stretch' => 'version 4.9+80+deb9u3',

    apt::pin { 'toolforge-linux-pinning':
        package  => $linux_pkg,
        pin      => $linux_pkg_version,
        priority => '1001',
    }

    #
    # pam libs
    #
    $libpam_pkg_version = $facts['os_version'] ? {
        'trusty'  => 'version 1.1.8-1ubuntu2.2',
        'jessie'  => 'version 1.1.8-3.1+deb8u1',
        'stretch' => 'version 1.1.8-3.6',

    apt::pin { 'toolforge-libpam-pinning':
        package  => 'libpam-runtime',
        pin      => $libpam_pkg_version,
        priority => '1001',
    }
}
