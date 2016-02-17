# Disable NFS client service daemons on hosts which have no need for them
# Only defined for jessie so far - if you want to use this with trusty
# targets, you'll have to figure out what that looks like here first!

class base::no_nfs_client {
    if os_version('debian >= jessie') {
        service { 'nfs-common':
            ensure => stopped,
            enable => false,
        }
        service { 'rpcbind':
            ensure => stopped,
            enable => false,
        }
    }
    else {
        error('base::no_nfs_client only supports jessie so far, please fix it for your use-case!')
    }
}
