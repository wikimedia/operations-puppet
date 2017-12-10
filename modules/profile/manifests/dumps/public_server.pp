# Profile for Dumps server in the Public VLAN,
# that serves dumps to Cloud VPS/Stat boxes via NFS,
# or via web or rsync to mirrors

class profile::dumps::public_server {
    class { '::dumpsuser': }
    class { '::dumps::deprecated::user': }
    class {'::public_dumps::server':}

}
