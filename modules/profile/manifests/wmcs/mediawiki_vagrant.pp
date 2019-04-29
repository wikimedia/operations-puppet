class profile::wmcs::mediawiki_vagrant(
) {
    include ::vagrant
    include ::vagrant::lxc
    include ::vagrant::mediawiki
}
