# Beta Cluster DB server
class profile::mariadb::beta {

    include profile::base::production
    require profile::mariadb::packages_wmf
    include profile::mariadb::wmfmariadbpy
    include passwords::misc::scripts
    include mariadb::stock_heartbeat

    class { 'mariadb::config':
        basedir => $profile::mariadb::packages_wmf::basedir,
        config  => 'role/mariadb/mysqld_config/beta.my.cnf.erb',
    }

    class { 'mariadb::service':
        ensure  => 'running',
        manage  => true,
        enable  => true,
        require => Class['mariadb::config'],
    }

    $password = $passwords::misc::scripts::mysql_beta_root_pass

    $prompt = 'BETA'
    file { '/root/.my.cnf':
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('mariadb/root.my.cnf.erb'),
    }
}
