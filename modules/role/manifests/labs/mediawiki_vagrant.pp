# Provision LXC, Vagrant and MediaWiki-Vagrant
#
# Install Linux Containers (LXC) and Vagrant along with helper programs and
# provision a MediaWiki-Vagrant clone for shared use.
#
class role::labs::mediawiki_vagrant {
    include ::profile::wmcs::mediawiki_vagrant

    # Ensure that secondary disks are mounted first if they are being used.
    Labs_lvm::Volume <| |> -> Class['role::labs::mediawiki_vagrant']
}
