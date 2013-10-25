# gluster::server
#
#  Install the glusterfs server package.
#
#   This doesn't do any config work at the moment.
#
class gluster::server {

    package { 'glusterfs-server':
        ensure => present;
    }

}
