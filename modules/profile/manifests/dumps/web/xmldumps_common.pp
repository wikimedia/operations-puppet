# Profile applied to the current dataset serving hosts
# Can be deprecated after migrating to labstore1006|7
class profile::dumps::web::xmldumps_common(
    $do_acme = hiera('do_acme'),
    $datadir = hiera('profile::dumps::distribution::basedatadir'),
    $xmldumpsdir = hiera('profile::dumps::distribution::xmldumpspublicdir'),
    $miscdatasetsdir = hiera('profile::dumps::distribution::miscdumpsdir'),
) {
    interface::add_ip6_mapped { 'main': }

    require profile::dumps::web::nginx

    # better here once than copy-pasted into multiple roles.
    require profile::dumps::nfs
    # Using profile in generation/server path to not break rsyncer and rsyncer_peer hiera calls
    require profile::dumps::generation::server::dumpstatusfiles_sync
    require profile::dumps::distribution::datasets::cleanup
    require profile::dumps::distribution::datasets::cleanup_miscdatasets

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
