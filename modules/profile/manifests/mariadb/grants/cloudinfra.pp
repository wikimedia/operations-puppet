class profile::mariadb::grants::cloudinfra (
    String $labspuppet_pass  = hiera('profile::mariadb::grants::cloudinfra::labspuppet_pass'),
    String $repl_pass        = hiera('profile::mariadb::grants::cloudinfra::repl_pass'),
) {
    file { '/etc/mysql/cloudinfra-grants.sql':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('profile/mariadb/grants/cloudinfra.sql.erb'),
    }
}
