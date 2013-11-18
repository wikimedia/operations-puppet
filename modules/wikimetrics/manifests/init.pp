# == Class wikimetrics
#
class wikimetrics(
    $path              = '/srv/wikimetrics',
    $celery_broker_url = 'redis://localhost:6379/0',
    $celery_result_url = 'redis://localhost:6379/0',
    $config_directory  = '/etc/wikimetrics'
)
{
    $user  = 'wikimetrics'
    $group = 'wikimetrics'


    group { $group:
      ensure => present,
      system => true,
    }

    user { $user:
      ensure     => present,
      gid        => $group,
      home       => $path,
      managehome => false,
      system     => true,
      require    => Group[$group],
    }

    git::clone { 'wikimetrics':
        directory => $path,
        origin    => 'git clone https://gerrit.wikimedia.org/r/analytics/wikimetrics',
        owner     => $user,
        group     => $group
    }

    file { $config_directory:
        ensure => 'directory',
    }
    file { "${config_directory}/db_config.yaml":
        content => template('wikimetrics/db_config.yaml.erb'),
    }
}
