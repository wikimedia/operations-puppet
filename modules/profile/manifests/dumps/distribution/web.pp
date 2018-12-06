class profile::dumps::distribution::web (
    $do_acme = hiera('do_acme'),
    $datadir = hiera('profile::dumps::distribution::basedatadir'),
    $xmldumpsdir = hiera('profile::dumps::distribution::xmldumpspublicdir'),
    $miscdatasetsdir = hiera('profile::dumps::distribution::miscdumpsdir'),
){
    # includes module for bandwidth limits
    class { '::nginx':
        variant => 'extras',
    }

    class { '::sslcert::dhparam': }
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

    # copy web server logs to stat host
    if $do_acme {
      class {'::dumps::web::rsync::nginxlogs':
          dest => 'stat1007.eqiad.wmnet::dumps-webrequest/',
      }
    }
}
