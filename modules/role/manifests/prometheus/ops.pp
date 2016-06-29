class role::prometheus::ops {
    $mysql_mw_targets_file = '/srv/prometheus/ops/targets/mysql-mw.yml'
    $mysql_mw_db_config = "/srv/mediawiki-config/wmf-config/db-${::site}.php"

    prometheus::server { 'ops':
        listen_address       => '127.0.0.1:9900',
        scrape_configs_extra => [
            {
                'job_name'        => 'mysql-mw',
                'file_sd_configs' => [ {
                    'names' => [ $mysql_mw_targets_file ]
                } ],
            },
        ],
    }

    prometheus::web { 'ops':
        proxy_pass => 'http://localhost:9900/ops',
    }

    include ::prometheus::scripts

    git::clone { 'operations/mediawiki-config':
        ensure    => 'latest',
        directory => '/srv/mediawiki-config',
        notify    => Exec['prometheus_mysql_mw_targets'],
    }

    $mysql_mw_targets_command = "/usr/local/bin/prometheus-mysql-mw-targets \
 --db-config ${mysql_mw_db_config} \
 --target-suffix .${::site}.wmnet:9104 > ${mysql_mw_targets_file}.$$ \
 && mv ${mysql_mw_targets_file}.$$ ${mysql_mw_targets_file}"

    exec { 'prometheus_mysql_mw_targets':
        command => $mysql_mw_targets_command,
        require => [
            File['/usr/local/bin/prometheus-mysql-mw-targets'],
            Git::Clone['operations/mediawiki-config'],
        ],
    }
}
