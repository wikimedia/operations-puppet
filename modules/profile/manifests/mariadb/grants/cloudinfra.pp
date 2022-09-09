class profile::mariadb::grants::cloudinfra (
    Array[Stdlib::Fqdn] $cloudinfra_dbs  = lookup('profile::mariadb::cloudinfra::cloudinfra_dbs'),
    Array[Stdlib::Fqdn] $enc_servers     = lookup('profile::mariadb::cloudinfra::enc_servers'),
    String              $labspuppet_pass = lookup('profile::mariadb::grants::cloudinfra::labspuppet_pass'),
    String              $repl_pass       = lookup('profile::mariadb::grants::cloudinfra::repl_pass'),
) {
    $repl_ips = $cloudinfra_dbs.map |Stdlib::Fqdn $fqdn| {
        ipresolve($fqdn, 4)
    }

    $labspuppet_client_ips = $enc_servers.map |Stdlib::Fqdn $fqdn| {
        ipresolve($fqdn, 4)
    }

    file { '/etc/mysql/cloudinfra-grants.sql':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('profile/mariadb/grants/cloudinfra.sql.erb'),
    }
}
