# DEPRECATED, DO NOT USE!
# Install Mediawiki-Vagrant puppet repo, manage manually from CLI
class role::deprecated::labsvagrant {

    # Mount secondary disk before applying labs_vagrant
    class { '::labs_vagrant':
        require => Class['::role::labs::lvm::srv'],
    }
}
