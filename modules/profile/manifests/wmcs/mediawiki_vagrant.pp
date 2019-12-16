class profile::wmcs::mediawiki_vagrant(
) {
    class { '::apparmor': }
    class { '::vagrant': }
    class { '::vagrant::lxc': }
    class { '::vagrant::mediawiki': }
}
