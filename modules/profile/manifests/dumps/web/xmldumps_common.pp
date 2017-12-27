class profile::dumps::web::xmldumps_common(
    $do_acme = hiera('do_acme'),
    $datadir = hiera('profile::dumps::basedatadir'),
    $xmldumpsdir = hiera('profile::dumps::xmldumpspublicdir'),
    $miscdatasetsdir = hiera('profile::dumps::miscdumpsdir'),
) {
    interface::add_ip6_mapped { 'main': }

    require profile::dumps::web::nginx

    # better here once than copy-pasted into multiple roles.
    require profile::dumps::nfs
    require profile::dumps::web::rsync_server
    require profile::dumps::web::dumpstatusfiles_sync
    require profile::dumps::web::cleanup
    require profile::dumps::web::cleanup_miscdatasets

    class { '::dumpsuser': }

    class {'::dumps::web::xmldumps':
        do_acme          => $do_acme,
        datadir          => $datadir,
        xmldumpsdir      => $xmldumpsdir,
        miscdatasetsdir  => $miscdatasetsdir,
        htmldumps_server => 'francium.eqiad.wmnet',
        xmldumps_server  => 'dumps.wikimedia.org',
        webuser          => 'dumpsgen',
        webgroup         => 'dumpsgen',
    }
}
