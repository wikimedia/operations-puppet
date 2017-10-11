class role::snapshot::common {
    include ::dumps::deprecated::user
    include ::standard
    include ::profile::base::firewall

    # mw packages and dependencies, dataset server nfs mount,
    # config files, stages files, dblists, html templates
    include ::role::mediawiki::common
    include ::snapshot::dumps

    # scap3 deployment of dump scripts
    include ::role::snapshot::deployment
}
