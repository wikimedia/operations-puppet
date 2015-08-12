# Provision LXC and Vagrant
#
# Install Linux Containers (LXC) and Vagrant along with helper programs for
# use as a generic vagrant container host.
#
class role::labs::vagrant_lxc {
    include ::vagrant
    include ::vagrant::lxc

    # Ensure that secondary disks are mounted first if they are being used.
    Labs_lvm::Volume <| |> -> Class['role::labs::vagrant_lxc']
}

