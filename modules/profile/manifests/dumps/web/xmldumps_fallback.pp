class profile::dumps::web::xmldumps_fallback(
    $do_acme = hiera('do_acme'),
    $datadir = hiera('profile::dumps::basedatadir'),
    $xmldumpsdir = hiera('profile::dumps::xmldumpspublicdir'),
    $miscdatasetsdir = hiera('profile::dumps::miscdumpsdir'),
) {
    interface::add_ip6_mapped { 'main': }

    require profile::dumps::web::nginx
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
