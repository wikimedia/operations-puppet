# This class holds all the apt pinning for key packages in the Toolforge cluster

class profile::toolforge::apt_pinning {
    #
    # linux kernel
    #
    # virtual meta-package, they usually have 3 levels of indirection:
    # linux-meta -> linux-meta-4.9 -> linux-image-4.9-xx
    $linux_meta_pkg =  'linux-image-amd64'
    case debian::codename() {
        'buster': {
            $linux_meta_pkg_version   = 'version 4.19+105+deb10u1'
            # actual kernel package. Pinning only this is not enough, given that the meta-package
            # could be upgraded pointing to another version and then you would have a pending reboot
            $linux_pkg                = 'linux-image-4.19.0-5-amd64'
            $linux_pkg_version        = 'version 4.19.37-5+deb10u2'
            $libpam_pkg_version       = 'version 1.3.1-5'
            $libpam_ldapd_pkg_version = 'version 0.9.10-2'
            $ldap_utils_pkg_version   = 'version 2.4.47+dfsg-3+deb10u1'
            $libnss3_pkg_version      = 'version 2:3.42.1-1+deb10u1'
            $libnfsidmap2_pkg_version = 'version 0.25-5.1'
            $ldapvi_pkg_version       = 'version 1.7-10*'
            $sudo_ldap_pkg_version    = 'version 1.8.27-1+deb10u3'
            $nscd_pkg_version         = 'version 2.28-10'
            $python_ldap_pkg_version  = 'version 3.1.0-2'
            $libnss_db_pkg_version    = 'version 2.2.3pre1-6+b6'
            $nfs_common_pkg_version   = 'version 1:1.3.4-2.5'
        }
        'stretch': {
            $linux_meta_pkg_version   = 'version 4.9+80+deb9u3'
            $linux_pkg                = 'linux-image-4.9.0-5-amd64'
            $linux_pkg_version        = 'version 4.9.65-3+deb9u2'
            $libpam_pkg_version       = 'version 1.1.8-3.6'
            $libpam_ldapd_pkg_version = 'version 0.9.7-2'
            $ldap_utils_pkg_version   = 'version 2.4.44+dfsg-5+deb9u1'
            $libnss3_pkg_version      = 'version 2:3.26.2-1.1+deb9u2'
            $libnss_db_pkg_version    = 'version 2.2.3pre1-6+b6'
            $libnfsidmap2_pkg_version = 'version 0.25-5.1'
            $ldapvi_pkg_version       = 'version 1.7-10*'
            $sudo_ldap_pkg_version    = 'version 1.8.19p1-2.1+deb9u3'
            $nscd_pkg_version         = 'version 2.24-11+deb9u1'
            $nfs_common_pkg_version   = 'version 1:1.3.4-2.1'
            $python_ldap_pkg_version  = 'version 2.4.28-0.1'
        }
        default: {
            fail("${debian::codename()}: not supported")
        }
    }
    apt::pin { 'toolforge-linux-meta-pinning':
        package  => $linux_meta_pkg,
        pin      => $linux_meta_pkg_version,
        priority => '1001',
    }
    apt::pin { 'toolforge-linux-pinning':
        package  => $linux_pkg,
        pin      => $linux_pkg_version,
        priority => '1001',
    }

    apt::pin { 'toolforge-libpam-pinning':
        package  => 'libpam-runtime libpam-modules* libpam0g',
        pin      => $libpam_pkg_version,
        priority => '1001',
    }
    apt::pin { 'toolforge-libpam-ldapd-pinning':
        package  => 'libpam-ldapd nslcd* libnss-ldapd',
        pin      => $libpam_ldapd_pkg_version,
        priority => '1001',
    }
    apt::pin { 'toolforge-ldapvi-pinning':
        package  => 'ldapvi',
        pin      => $ldapvi_pkg_version,
        priority => '1001',
    }
    apt::pin { 'toolforge-sudo-ldap-pinning':
        package  => 'sudo-ldap',
        pin      => $sudo_ldap_pkg_version,
        priority => '1001',
    }
    apt::pin { 'toolforge-nscd-pinning':
        package  => 'nscd',
        pin      => $nscd_pkg_version,
        priority => '1001',
    }
    apt::pin { 'toolforge-libnss-db-pinning':
        package  => 'libnss-db',
        pin      => $libnss_db_pkg_version,
        priority => '1001',
    }
    apt::pin { 'toolforge-python-ldap-pinning':
        package  => 'python-ldap',
        pin      => $python_ldap_pkg_version,
        priority => '1001',
    }
    apt::pin { 'toolforge-ldap-utils-pinning':
        package  => 'ldap-utils libldap*',
        pin      => $ldap_utils_pkg_version,
        priority => '1001',
    }
    apt::pin { 'toolforge-libnss3-pinning':
        package  => 'libnss3**',
        pin      => $libnss3_pkg_version,
        priority => '1001',
    }
    # sssd
    if debian::codename::eq('buster') {
        apt::pin { 'toolforge-sssd-pinning':
            package  => 'sssd*',
            pin      => 'version 1.16.3-3.2',
            priority => '1001',
        }
    }

    apt::pin { 'toolforge-nfs-common-pinning':
        package  => 'nfs-common',
        pin      => $nfs_common_pkg_version,
        priority => '1001',
    }
    apt::pin { 'toolforge-libnfsidmap2-pinning':
        package  => 'libnfsidmap2',
        pin      => $libnfsidmap2_pkg_version,
        priority => '1001',
    }
}
