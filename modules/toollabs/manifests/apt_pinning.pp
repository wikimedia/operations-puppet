# This class holds all the apt pinning for key packages in the Toolforge

class toollabs::apt_pinning {

    #
    # linux kernel
    #
    if os_version('ubuntu == trusty') {
       apt::pin { 'linux-image-generic':
           pin      => 'version 3.13.0.141.151',
           priority => '1001',
       }
    }
    if os_version('debian == jessie') {
       apt::pin { 'linux-meta-4.9':
           pin      => 'version 1.16',
           priority => '1001',
       }
    }
    if os_version('debian == stretch') {
       apt::pin { 'linux-image-amd64':
           pin      => 'version 4.9+80+deb9u3',
           priority => '1001',
       }
    }
}
