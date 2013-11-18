# == Class wikimetrics::queue
#
# Starts redis-serfver and the wikimetrics-queue service.
# This class does not currently support running a redis instance
# on a different node than the wikimetrics-queue service.
#
# This class depends on the redis module.
class wikimetrics::queue
{
    Class['wikimetrics'] -> Class['wikimetrics::queue']

    # install and set up redis using the redis module.
    class { '::redis':
        dir           => '/var/lib/redis',
        # disable persist here so we can manaully specify our save options
        persist       => 'disabled',
        redis_options => {
            'save' => "900 1\nsave 300 10\nsave 60 20",
        },
    }

    $config_directory = $::wikimetrics::config_directory
    $wikimetrics_path = $::wikimetrics::path
    # install upstart init file
    file { '/etc/init/wikimetrics-queue.conf':
        content => template('wikimetrics/upstart.wikimetrics-queue.conf.erb')
    }

    service { 'wikimetrics-queue':
        ensure     => 'running',
        provider   => 'upstart',
        hasrestart => true,
        require    => [
            Class['::redis'],
            File['/etc/init/wikimetrics-queue.conf'],
        ],
    }
}
