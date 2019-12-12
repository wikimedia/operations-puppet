# Class: ceph::admin
#
# This class manages the Ceph admin client.
#
# Parameters
#    - $data_dir
#        Path to the base Ceph data directory
#    - $admin_keyring
#        File name and path to install the admin keyring
#    - $admin_keydata
#        base64 encoded key used to create the keyring
class ceph::admin(
    Stdlib::AbsolutePath $admin_keyring,
    Stdlib::Unixpath     $data_dir,
    String               $admin_keydata,
) {
    Class['ceph'] -> Class['ceph::admin']

    package { 'ceph':
        ensure => present,
    }

    ceph::keyring { 'client.admin':
        cap_mds => 'allow *',
        cap_mgr => 'allow *',
        cap_mon => 'allow *',
        cap_osd => 'allow *',
        keydata => $admin_keydata,
        keyring => $admin_keyring,
    }
}
