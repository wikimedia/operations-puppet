# == Class wikimetrics::queue(
#
class wikimetrics::queue
{
    Class['wikimetrics'] -> Class['wikimetrics::queue']

    $config_directory = $::wikimetrics::config_directory
    $wikimetrics_path = $::wikimetrics::path
    # install upstart init file
    file { '/etc/init/wikimetrics-queue.conf':
        content => template('wikimetrics/upstart.wikimetrics-queue.conf.erb')
    }

    # package { 'redis-server':
    #     ensure => 'installed'
    # }
    service { 'wikimetrics-queue':
        ensure     => 'running',
        provider   => 'upstart',
        hasrestart => true,
        require    => File['/etc/init/wikimetrics-queue.conf'],
    }
}
