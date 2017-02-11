class role::snapshot::common {
    include ::dataset::user
    include standard
    include ::base::firewall

    # mw packages and dependencies, dataset server nfs mount,
    # config files, stages files, dblists, html templates
    include ::role::mediawiki::common
    include snapshot::dumps

    # scap3 deployment of dump scripts
    include snapshot::deployment
}

