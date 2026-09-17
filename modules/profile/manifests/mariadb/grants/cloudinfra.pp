class profile::mariadb::grants::cloudinfra (
    Array[Stdlib::Fqdn]        $cloudinfra_dbs  = lookup('profile::mariadb::cloudinfra::cloudinfra_dbs'),
    Array[Stdlib::Fqdn]        $enc_servers     = lookup('profile::mariadb::cloudinfra::enc_servers'),
    Array[Stdlib::IP::Address] $proxies         = lookup('cache_hosts'),
    Array[Stdlib::Fqdn]        $backup_hosts    = lookup('profile::wmcs::cloudinfra::backup_hosts'),
    String                     $labspuppet_pass = lookup('profile::mariadb::grants::cloudinfra::labspuppet_pass'),
    String                     $webproxy_pass   = lookup('profile::mariadb::grants::cloudinfra::webproxy_pass'),
    String                     $repl_pass       = lookup('profile::mariadb::grants::cloudinfra::repl_pass'),
    String                     $backup_pass     = lookup('profile::mariadb::grants::cloudinfra::backup_pass'),
) {
    $repl_ips = $cloudinfra_dbs.wmflib::hosts2ips()
    $labspuppet_client_ips = $enc_servers.wmflib::hosts2ips()
    $backup_ips = $backup_hosts.wmflib::hosts2ips()

    file { '/etc/mysql/cloudinfra-grants.sql':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('profile/mariadb/grants/cloudinfra.sql.erb'),
    }
}
