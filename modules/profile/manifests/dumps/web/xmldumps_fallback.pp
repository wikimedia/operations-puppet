class profile::dumps::web::xmldumps_fallback(
    $do_acme = hiera('do_acme'),
    $xmldumpsdir = hiera('profile::dumps::xmldumpspublicdir'),
    $miscdatasetsdir = hiera('profile::dumps::miscdumpsdir'),
) {
    class { '::dumpsuser': }

    class {'::dumps::web::xmldumps':
        do_acme          => $do_acme,
        datadir          => '/data/xmldatadumps',
        xmldumpsdir      => $xmldumpsdir,
        miscdatasetsdir  => $miscdatasetsdir,
        htmldumps_server => 'francium.eqiad.wmnet',
        xmldumps_server  => 'dumps.wikimedia.org',
        webuser          => 'dumpsgen',
        webgroup         => 'dumpsgen',
    }
}
