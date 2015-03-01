# Provision LXC, Vagrant and MediaWiki-Vagrant
#
# Install Linux Containers (LXC) and Vagrant along with helper programs and
# provision a MediaWiki-Vagrant clone for shared use.
#
# Conflicts with role::labs_vagrant.
class role::mediawiki_vagrant_lxc {
    require ::role::labs::lvm::srv
    include ::vagrant
    include ::vagrant::lxc
    include ::vagrant::mediawiki
}
