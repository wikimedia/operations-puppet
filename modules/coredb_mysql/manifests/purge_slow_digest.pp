# class for purging slow query digest log history
class coredb_mysql::purge_slow_digest {

    include passwords::mysql::querydigest

    $mysql_user = 'ops'
    $digest_host = 'db1001.eqiad.wmnet'
    $digest_slave = 'db1016.eqiad.wmnet'
    $digest_db = 'query_digests'

    file { '/usr/local/bin/purge_query_digest.sh':
        owner   => 'root',
        group   => 'root',
        mode    => '0500',
        content => template('coredb_mysql/purge_query_digest.sh.erb'),
    }

    cron { 'purge_slow_digest':
        ensure  => present,
        command => '/usr/local/bin/purge_query_digest.sh >/dev/null 2>&1',
        require => File['/usr/local/bin/purge_query_digest.sh'],
        user    => 'root',
        weekday => 0,
        hour    => 3,
        minute  => 30,
    }
}
