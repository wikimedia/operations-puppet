# Allocate all of the instance's extra space as /var/log for instances with noisy logs
class role::labs::lvm::biglogs {
    include labs_lvm
    labs_lvm::volume { 'second-local-disk': mountat => '/var/log' }
}
