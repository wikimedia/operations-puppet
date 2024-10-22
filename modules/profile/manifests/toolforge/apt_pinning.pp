# This class holds all the apt pinning for key packages in the Toolforge cluster

class profile::toolforge::apt_pinning {
    case debian::codename() {
        'bullseye': {
            $libnfsidmap2_pkg_version = 'version 0.25-6'
            $nfs_common_pkg_version   = 'version 1:1.3.4-6'
        }

        'buster': {
            $libnfsidmap2_pkg_version = 'version 0.25-5.1'
            $nfs_common_pkg_version   = 'version 1:1.3.4-2.5'
        }
        default: {
            fail("${debian::codename()}: not supported")
        }
    }

    apt::pin { [
        'toolforge-libpam-pinning',
        'toolforge-libpam-ldapd-pinning',
        'toolforge-libnss-db-pinning',
        'toolforge-libpam-ldapd-pinning',
        'toolforge-ldap-utils-pinning',
        'toolforge-libnss3-pinning',
    ]:
        ensure   => absent,
        pin      => 'not used',
        priority => -1,
    }

    apt::pin { 'toolforge-nfs-common-pinning':
        package  => 'nfs-common',
        pin      => $nfs_common_pkg_version,
        priority => 1001,
    }
    apt::pin { 'toolforge-libnfsidmap2-pinning':
        package  => 'libnfsidmap2',
        pin      => $libnfsidmap2_pkg_version,
        priority => 1001,
    }
}
