# Please use separate .cnf templates for each type of server.

class mariadb::tendril::config {

    include passwords::misc::scripts

    class { 'mariadb::config':
        config   => 'beta.my.cnf.erb',
        prompt   => 'TENDRIL',
        password => $passwords::misc::scripts::mysql_root_pass,
        datadir  => '/a/sqldata',
        tmpdir   => '/a/tmp',
    }
}
