# Provision LXC, Vagrant and MediaWiki-Vagrant
#
# Install Linux Containers (LXC) and Vagrant along with helper programs and
# provision a MediaWiki-Vagrant clone for shared use.
#
# Conflicts with role::labs_vagrant.
class role::mediawiki_vagrant_lxc {
    include ::vagrant
    include ::vagrant::lxc
    include ::vagrant::mediawiki

    # Ensure that secondary disks are mounted first if they are being used.
    Labs_lvm::Volume <| |> -> Class['role::mediawiki_vagrant_lxc']

    # Ensure that role::labs_vagrant is not applied
    if defined(Class['role::labs_vagrant']) {
        fail('role::mediawiki_vagrant_lxc and role::labs_vagrant conflict.')
    }
}
