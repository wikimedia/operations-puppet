class role::snapshot::common {
    include ::dataset::user
    include base::firewall

    # mw packages and dependencies, dataset server nfs mount,
    include snapshot::dumps::packages

    # config files, stages files, dblists, html templates
    include snapshot::dumps

    # scap3 deployment of dump scripts
    include snapshot::deployment
}

