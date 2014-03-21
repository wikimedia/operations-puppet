# Please use separate .cnf templates for each type of server..

class mariadb::beta::config {

    include passwords::misc::scripts

    class { 'mariadb::config':
        config   => 'beta.my.cnf.erb',
        prompt   => 'BETA',
        password => $passwords::misc::scripts::mysql_beta_root_pass,
        datadir  => '/mnt/sqldata',
        tmpdir   => '/mnt/tmp',
    }
}