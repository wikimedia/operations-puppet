# Install Mediawiki-Vagrant puppet repo, manage manually from CLI
class role::labs::vagrant {
    require ::role::labs::lvm::srv
    include ::labs_vagrant
}
