# SPDX-License-Identifier: Apache-2.0
class install_server::efiboot {

    file { '/srv/efiboot':
        ensure  => directory,
        mode    => '0444',
        source  => 'puppet:///modules/install_server/efiboot',
        recurse => true,
        force   => true,
        purge   => true,
    }

    package { 'ipxe':
        ensure => installed,
    }

    # Use the snponly variant of iPXE which utilizes the vendor supplied UEFI
    # networking drivers instead of iPXE's own network driver code:
    #   https://ipxe.org/appnote/buildtargets
    # At least in the case of supermicro, the vendor supplied drivers seem
    # to be more reliable.
    file { '/srv/efiboot/snponly.efi':
        ensure  => file,
        # We could use a symlink, but puppet happily creates dangling
        # symlinks, so copy our file instead
        source  => 'file:///usr/lib/ipxe/snponly.efi',
        require => Package['ipxe'],
    }
}
