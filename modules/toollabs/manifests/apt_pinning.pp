# This class holds all the apt pinning for key packages in the Toolforge

class toollabs::apt_pinning {

    #
    # linux kernel
    #
    if os_version('ubuntu == trusty') {
        apt::pin { 'toolforge-linux-pinning':
            package  => 'linux-image-generic',
            pin      => 'version 3.13.0.141.151',
            priority => '1001',
        }
    }
    if os_version('debian == jessie') {
        apt::pin { 'toolforge-linux-pinning':
            package  => 'linux-meta',
            pin      => 'version 1.16',
            priority => '1001',
        }
    }
    if os_version('debian == stretch') {
        apt::pin { 'toolforge-linux-pinning':
            package  => 'linux-image-amd64',
            pin      => 'version 4.9+80+deb9u3',
            priority => '1001',
        }
    }

    #
    # pam libs
    #
    if os_version('ubuntu == trusty') {
        apt::pin { 'toolforge-libpam-pinning':
            package  => 'libpam-runtime',
            pin      => 'version 1.1.8-1ubuntu2.2',
            priority => '1001',
        }
    }
    if os_version('debian == jessie') {
        apt::pin { 'toolforge-libpam-pinning':
            package  => 'libpam-runtime',
            pin      => 'version 1.1.8-3.1+deb8u1',
            priority => '1001',
        }
    }
    if os_version('debian == stretch') {
        apt::pin { 'toolforge-libpam-pinning':
            package  => 'libpam-runtime',
            pin      => 'version 1.1.8-3.6',
            priority => '1001',
        }
    }
}
