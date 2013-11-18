# == Class wikimetrics
#
class wikimetrics(
    # path in which to install wikimetrics
    $path              = '/srv/wikimetrics',

    # celery broker and result urls.  Should be redis server URLs
    $celery_broker_url = 'redis://localhost:6379/0',
    $celery_result_url = 'redis://localhost:6379/0',

    # VirtualHost ServerName of wikimetrics webserver
    $server_name,
    # if true, site is expected to be served via HTTPS.
    $ssl_redirect           = true,
    # VirtualHost ServerAliases.
    $server_aliases         = [],

    # Flask login secret key
    $flask_secret_key,

    # Mediawiki OAuth
    $meta_mw_consumer_key,
    $meta_mw_client_secret,

    # Google Auth
    $google_client_secret,
    $google_client_id,
    $google_client_email,

    # Wikimetrics Database Creds
    $db_user_wikimetrics,
    $db_pass_wikimetrics,
    $db_host_wikimetrics,
    $db_name_wikimetrics,

    # LabsDB Database Creds
    $db_user_labsdb,
    $db_pass_labsdb,

    $config_directory  = '/etc/wikimetrics',
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

    # db_config, queue_config, web_config
    file { "${config_directory}/db_config.yaml":
        content => template('wikimetrics/db_config.yaml.erb'),
    }
    file { "${wikimetrics::config_directory}/queue_config.yaml":
        content => template('wikimetrics/queue_config.yaml.erb')
    }
    file { "${wikimetrics::config_directory}/web_config.yaml":
        content => template('wikimetrics/web_config.yaml.erb')
    }

    if !defined(Package['gcc']) {
        package { 'gcc': ensure => 'installed' }
    }
    if !defined(Package['python-dev']) {
        package { 'python-dev': ensure => 'installed' }
    }
    if !defined(Package['libmysqlclient-dev']) {
        package { 'libmysqlclient-dev': ensure => 'installed' }
    }

    # This class will not fully install dependencies for wikimetrics.
    # To finish the installation, you must do the following:
    #
    # Install newer pip:
    #   wget https://pypi.python.org/packages/source/p/pip/pip-1.4.1.tar.gz && tar -xvzf pip-1.4.1.tar.gz && cd pip-1.4.1 && easy_install
    #
    # Install wikimetrics dependencies
    #   cd $path; /usr/local/bin/pip install -e .
}
