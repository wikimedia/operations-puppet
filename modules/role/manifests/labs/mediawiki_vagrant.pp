# Provision LXC, Vagrant and MediaWiki-Vagrant
#
# Install Linux Containers (LXC) and Vagrant along with helper programs and
# provision a MediaWiki-Vagrant clone for shared use.
#
# Conflicts with role::labs_vagrant.
#
# filtertags: labs-common
class role::labs::mediawiki_vagrant {
    include ::vagrant
    include ::vagrant::lxc
    include ::vagrant::mediawiki

    if !os_version('debian == jessie') {
        # T180377
        warning('Currently this role is only supported on Debian Jessie.')
    }

    # Ensure that secondary disks are mounted first if they are being used.
    Labs_lvm::Volume <| |> -> Class['role::labs::mediawiki_vagrant']

    # Ensure that role::labs_vagrant is not applied
    if defined(Class['role::labs_vagrant']) {
        fail('role::labs::mediawiki_vagrant and role::labs_vagrant conflict.')
    }
}
