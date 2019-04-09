# This class holds all the apt pinning for key packages in the Toolforge cluster

class toollabs::apt_pinning {

    #
    # linux kernel
    #
    # virtual meta-package, they usually have 3 levels of indirection:
    # linux-meta -> linux-meta-4.9 -> linux-image-4.9-xx
    $linux_meta_pkg = $facts['lsbdistcodename'] ? {
        'jessie'  => 'linux-meta*',
        'stretch' => 'linux-image-amd64',
    }
    $linux_meta_pkg_version = $facts['lsbdistcodename'] ? {
        'jessie'  => 'version 1.16',
        'stretch' => 'version 4.9+80+deb9u3',
    }
    apt::pin { 'toolforge-linux-meta-pinning':
        package  => $linux_meta_pkg,
        pin      => $linux_meta_pkg_version,
        priority => '1001',
    }
    # actual kernel package. Pinning only this is not enough, given that the meta-package
    # could be upgraded pointing to another version and then you would have a pending reboot
    $linux_pkg = $facts['lsbdistcodename'] ? {
        'jessie'  => 'linux-image-4.9.0-0.bpo.5-amd64',
        'stretch' => 'linux-image-4.9.0-5-amd64',
    }
    $linux_pkg_version = $facts['lsbdistcodename'] ? {
        'jessie'  => 'version 4.9.65-3+deb9u1~bpo8+2',
        'stretch' => 'version 4.9.65-3+deb9u2',
    }
    apt::pin { 'toolforge-linux-pinning':
        package  => $linux_pkg,
        pin      => $linux_pkg_version,
        priority => '1001',
    }

    #
    # nss/ldap/pam libs and related packages
    #
    # dpkg -l | grep ^ii | egrep libnss\|ldap\|nscd\|nslcd\|pam | awk -F' ' '{print $3" "$2}' | sort -n
    # libpam-runtime libpam-modules* libpam0g
    $libpam_pkg_version = $facts['lsbdistcodename'] ? {
        'jessie'  => 'version 1.1.8-3.1+deb8u1*',
        'stretch' => 'version 1.1.8-3.6',
    }
    apt::pin { 'toolforge-libpam-pinning':
        package  => 'libpam-runtime libpam-modules* libpam0g',
        pin      => $libpam_pkg_version,
        priority => '1001',
    }
    # libpam-ldapd nslcd* libnss-ldapd
    $libpam_ldapd_pkg_version = $facts['lsbdistcodename'] ? {
        'jessie'  => 'version 0.9.4-3+deb8u1',
        'stretch' => 'version 0.9.7-2',
    }
    apt::pin { 'toolforge-libpam-ldapd-pinning':
        package  => 'libpam-ldapd nslcd* libnss-ldapd',
        pin      => $libpam_ldapd_pkg_version,
        priority => '1001',
    }
    # ldapvi
    $ldapvi_pkg_version = $facts['lsbdistcodename'] ? {
        'jessie'  => 'version 1.7-9',
        'stretch' => 'version 1.7-10*',
    }
    apt::pin { 'toolforge-ldapvi-pinning':
        package  => 'ldapvi',
        pin      => $ldapvi_pkg_version,
        priority => '1001',
    }
    # sudo-ldap
    $sudo_ldap_pkg_version = $facts['lsbdistcodename'] ? {
        'jessie'  => 'version 1.8.10p3-1+deb8u5',
        'stretch' => 'version 1.8.19p1-2.1',
    }
    apt::pin { 'toolforge-sudo-ldap-pinning':
        package  => 'sudo-ldap',
        pin      => $sudo_ldap_pkg_version,
        priority => '1001',
    }
    # nscd
    $nscd_pkg_version = $facts['lsbdistcodename'] ? {
        'jessie'  => 'version 2.19-18+deb8u10',
        'stretch' => 'version 2.24-11+deb9u1',
    }
    apt::pin { 'toolforge-nscd-pinning':
        package  => 'nscd',
        pin      => $nscd_pkg_version,
        priority => '1001',
    }
    # libnss-db
    $libnss_db_pkg_version = $facts['lsbdistcodename'] ? {
        'jessie'  => 'version 2.2.3pre1-5+b3',
        'stretch' => 'version 2.2.3pre1-6+b1',
    }
    apt::pin { 'toolforge-libnss-db-pinning':
        package  => 'libnss-db',
        pin      => $libnss_db_pkg_version,
        priority => '1001',
    }
    # python-ldap
    $python_ldap_pkg_version = $facts['lsbdistcodename'] ? {
        'jessie'  => 'version 2.4.10-1',
        'stretch' => 'version 2.4.28-0.1',
    }
    apt::pin { 'toolforge-python-ldap-pinning':
        package  => 'python-ldap',
        pin      => $python_ldap_pkg_version,
        priority => '1001',
    }
    # ldap-utils libldap*
    $ldap_utils_pkg_version = $facts['lsbdistcodename'] ? {
        'jessie'  => 'version 2.4.41+dfsg-1+wmf1',
        'stretch' => 'version 2.4.44+dfsg-5+deb9u1',
    }
    apt::pin { 'toolforge-ldap-utils-pinning':
        package  => 'ldap-utils libldap*',
        pin      => $ldap_utils_pkg_version,
        priority => '1001',
    }
    # libnss3*
    $libnss3_pkg_version = $facts['lsbdistcodename'] ? {
        'jessie'  => 'version 2:3.26-1+debu8u3',
        'stretch' => 'version xxx',
    }
    apt::pin { 'toolforge-libnss3-pinning':
        package  => 'libnss3**',
        pin      => $libnss3_pkg_version,
        priority => '1001',
    }

    #
    # kubernetes stuff
    #
    # main k8s
    if os_version('debian == jessie') {
        apt::pin { 'toolforge-kubernetes-node-pinning':
            package  => 'kubernetes-node',
            pin      => 'version 1.4.6-6',
            priority => '2000',
        }
        apt::pin { 'toolforge-kubernetes-master-pinning':
            package  => 'kubernetes-master',
            pin      => 'version 1.4.6-6',
            priority => '2000',
        }
        apt::pin { 'toolforge-kubernetes-client-pinning':
            package  => 'kubernetes-client',
            pin      => 'version 1.4.6-3',
            priority => '2000',
        }
    }
    # paws
    if os_version('debian == stretch') {
        apt::pin { 'toolforge-kubeadm-pinning':
            package  => 'kubeadm',
            pin      => 'version 1.9.4-00',
            priority => '1001',
        }
        apt::pin { 'toolforge-kubelet-pinning':
            package  => 'kubelet',
            pin      => 'version 1.9.4-00',
            priority => '1001',
        }
        apt::pin { 'toolforge-kubectl-pinning':
            package  => 'kubectl',
            pin      => 'version 1.9.4-00',
            priority => '1001',
        }
        apt::pin { 'toolforge-kubernetes-cni-pinning':
            package  => 'kubernetes-cni',
            pin      => 'version 0.6.0-00',
            priority => '1001',
        }
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
    if os_version('debian == jessie') {
        $nginx_pkg_version = $facts['lsbdistcodename'] ? {
            'jessie'  => 'version 1.13.6-2+wmf1~jessie1',
        }
        apt::pin { 'toolforge-nginx-pinning':
            package  => 'nginx-*',
            pin      => $nginx_pkg_version,
            priority => '1001',
        }
    }

    #
    # apache stuff
    #
    if os_version('debian == jessie') {
        apt::pin { 'toolforge-apache2-pinning':
            package  => 'apache2',
            pin      => 'version 2.4.10-10+deb8u12+wmf1',
            priority => '1001',
        }
    }

    #
    # NFS libs and related packages
    #
    # nfs-common
    $nfs_common_pkg_version = $facts['lsbdistcodename'] ? {
        'jessie'  => 'version 1:1.2.8-9',
        'stretch' => 'version 1:1.3.4-2.1',
    }
    apt::pin { 'toolforge-nfs-common-pinning':
        package  => 'nfs-common',
        pin      => $nfs_common_pkg_version,
        priority => '1001',
    }
    # libnfsidmap2
    $libnfsidmap2_pkg_version = $facts['lsbdistcodename'] ? {
        'jessie'  => 'version 0.25-5',
        'stretch' => 'version 0.25-5.1',
    }
    apt::pin { 'toolforge-libnfsidmap2-pinning':
        package  => 'libnfsidmap2',
        pin      => $libnfsidmap2_pkg_version,
        priority => '1001',
    }
}
