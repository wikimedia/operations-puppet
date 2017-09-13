# web server of xml/sql dumps and other datasets
# also permits rsync from public mirrors and certain internal hosts
# lastly, serves thse files via nfs to certain internal hosts
class role::dumps::web::xmldumps {
    include ::profile::dumps::web::xmldumps
    include ::profile::dumps::web::rsync_server
    include ::profile::dumps::nfs_server

    system::role { 'role::dumps::web::xmldumps': description => 'web, nfs and rsync server of xml/sql dumps' }

    monitoring::service { 'http':
        description   => 'HTTP',
        check_command => 'check_http'
    }

    # TODO: move hiera lookup to parameter of a profile class
    if hiera('do_acme', true) {
        monitoring::service { 'https':
            description   => 'HTTPS',
            check_command => 'check_ssl_http_letsencrypt!dumps.wikimedia.org',
        }
    }
}
