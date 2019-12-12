# == Define: ceph::keyring
#
# Manages Ceph keyrings used for accessing the storage cluster.
#
# === Parameters
#
# [*ensure*]
#   If 'present', config will be enabled; if 'absent', disabled.
#   The default is 'present'.
#
# [*keyring*]
#   The absolute path of the keyring file.
#
# [*cluster*]
#   The name of the Ceph cluster
#   The default is 'ceph'.
#
# [*owner*]
#   The keyring file owner
#   The default is 'ceph'.
#
# [*group*]
#   The keyring file group
#   The default is 'ceph'.
#
# [*mode*]
#   The keyring file mode
#   The default is '0600'.
#
# [*cap_mds*]
#   The metadata service capabilities to grant this keyring
#   The default is 'undef'.
#
# [*cap_mgr*]
#   The manager capabilities to grant this keyring
#   The default is 'undef'.
#
# [*cap_mon*]
#   The monitor capabilities to grant this keyring
#   The default is 'undef'.
#
# [*cap_osd*]
#   The object storage daemon capabilities to grant this keyring
#   The default is 'undef'.
#
# [*keydata*]
#   Optional base64 keydata used to create the keyring
#   The default is 'undef'.
#
define ceph::keyring(
    Stdlib::AbsolutePath $keyring,
    String               $cluster = 'ceph',
    String               $ensure  = 'present',
    String               $group   = 'ceph',
    String               $mode    = '0600',
    String               $owner   = 'ceph',
    Optional[String]     $cap_mds = undef,
    Optional[String]     $cap_mgr = undef,
    Optional[String]     $cap_mon = undef,
    Optional[String]     $cap_osd = undef,
    Optional[String]     $keydata = undef,
) {
    # If a keydata was provided use ceph-authtool, else use ceph auth get-or-create
    if $keydata {
        $opt_prefix = '--cap'
    } else {
        $opt_prefix = undef
    }

    if $ensure == 'present' {
        if $cap_mds {
            $mds_opts = "${opt_prefix} mds '${cap_mds}'"
        }
        if $cap_mgr {
            $mgr_opts = "${opt_prefix} mgr '${cap_mgr}'"
        }
        if $cap_mon {
            $mon_opts = "${opt_prefix} mon '${cap_mon}'"
        }
        if $cap_osd {
            $osd_opts = "${opt_prefix} osd '${cap_osd}'"
        }

        $opts = "${mds_opts} ${mgr_opts} ${mon_opts} ${osd_opts}"

        if $keydata {
            exec { "ceph-keyring-${name}":
                command => "/usr/bin/ceph-authtool --create-keyring ${keyring} \
                            -n ${name} --add-key=${keydata} ${opts}",
                creates => $keyring,
            }
        } else {
            exec { "ceph-keyring-${name}":
                command => "/usr/bin/ceph auth get-or-create ${name} ${opts} -o ${keyring}",
                creates => $keyring,
            }
        }
    }

    file { $keyring:
        ensure => $ensure,
        owner  => $owner,
        group  => $group,
        mode   => $mode,
    }
}
