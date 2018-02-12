# This class holds all the apt pinning for key packages in the Toolforge

class toollabs::apt_pinning {

    #
    # linux kernel
    #
    $linux_pkg = $facts['os_version'] ? {
        'trusty'  => 'linux-image-generic',
        'jessie'  => 'linux-image-4.9.0-0.bpo.5-amd64',
        'stretch' => 'linux-image-4.9.0-5-amd64',
    }
    $linux_pkg_version = $facts['os_version'] ? {
        'trusty'  => 'version 3.13.0.141.151',
        'jessie'  => 'version 4.9.65-3+deb9u1~bpo8+2',
        'stretch' => 'version 4.9.65-3+deb9u2',
    }
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
    }
    apt::pin { 'toolforge-libpam-pinning':
        package  => 'libpam-runtime',
        pin      => $libpam_pkg_version,
        priority => '1001',
    }

    #
    # kubernetes stuff
    #
    apt::pin { 'toolforge-kubernetes-client-pinning':
        package  => 'kubernetes-client',
        pin      => 'version 1.4.6-6',
        priority => '1001',
    }
    apt::pin { 'toolforge-kubernetes-node-pinning':
        package  => 'kubernetes-node',
        pin      => 'version 1.4.6-6',
        priority => '1001',
    }
    apt::pin { 'toolforge-kubeadm-pinning':
        package  => 'kubeadm',
        pin      => 'version 1.9.1-00',
        priority => '1001',
    }
    apt::pin { 'toolforge-kubelet-pinning':
        package  => 'kubelet',
        pin      => 'version 1.9.1-00',
        priority => '1001',
    }
    apt::pin { 'toolforge-kubectl-pinning':
        package  => 'kubectl',
        pin      => 'version 1.9.1-00',
        priority => '1001',
    }
    apt::pin { 'toolforge-kubernetes-cni-pinning':
        package  => 'kubernetes-cni',
        pin      => 'version 0.6.0-00',
        priority => '1001',
    }

    #
    # nginx stuff
    #


    if os_version('debian == jessie') {
        apt::pin { 'toolforge-libnginx-mod-pinning':
            package  => 'libnginx-mod*',
            pin      => 'version 1.13.6-2+wmf1~jessie1',
            priority => '1001',
        }
    }
    $nginx_pkg_version = $facts['os_version'] ? {
        'trusty'  => 'version 1.4.6-1ubuntu3.8',
        'jessie'  => 'version 1.13.6+wmf1~jessie1',
    }
    apt::pin { 'toolforge-nginx-pinning':
        package  => 'nginx-*',
        pin      => $nginx_pkg_version,
        priority => '1001',
    }

}
