# Install Mediawiki-Vagrant puppet repo, manage manually from CLI
class role::labs::vagrant {
    include ::role::labs::lvm::srv

    # Mount secondary disk before applying labs_vagrant
    class { '::labs_vagrant':
        require => Class['::role::labs::lvm::srv'],
    }
}
