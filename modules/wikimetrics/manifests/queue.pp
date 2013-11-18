# == Class wikimetrics::queue(
#
class wikimetrics::queue(
    # Wikimetrics Database Creds
    $db_user_wikimetrics,
    $db_pass_wikimetrics,
    $db_host_wikimetrics,
    $db_name_wikimetrics,
    # Mediawiki Database Creds
    $db_user_mediawiki,
    $db_pass_mediawiki,
    $db_host_mediawiki,
    $db_name_mediawiki,
)
{
    Class['wikimetrics'] -> Class['wikimetrics::queue']

    file { "${wikimetrics::config_directory}/queue_config.yaml":
        content => template('wikimetrics/queue_config.yaml.erb')
    }

    $wikimetrics_path = $wikimetrics::path
    # install upstart init file
    file { '/etc/init/wikimetrics-queue.conf':
        content => template('wikimetrics/upstart.wikimetrics-queue.conf.erb')
    }

    service { 'wikimetrics-queue':
        ensure     => 'running',
        provider   => 'upstart',
        hasrestart => true,
        require    => [
            File['/etc/init/wikimetrics-queue.conf'],
            File["${wikimetrics::config_directory}/queue_config.yaml"]
        ],
    }
}
