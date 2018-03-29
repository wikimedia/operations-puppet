# Profile for Dumps distribution server in the Public VLAN,
# that serves dumps to Cloud VPS/Stat boxes via NFS,
# or via web or rsync to mirrors

class profile::dumps::distribution::monitoring {

    class { '::labstore::monitoring::interfaces': }

}
