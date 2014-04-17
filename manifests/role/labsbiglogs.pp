# Allocate an 8G partition at /var/log for instances with noisy logs
class role::labs::lvm::biglogs(
    $size = '8G'
) {
    include labs_lvm
    labs_lvm::volume { 'logfile-disk': mountat => '/var/log', size => $size }
}
