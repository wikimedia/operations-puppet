class role::labs::lvm::swift {
    include labs_lvm
    labs_lvm::volume { 'second-local-disk':
        mountat => '/srv/swift-storage/swiftstore',
        mountowner => 'swift',
        mountgroup => 'swift',
    }
}
