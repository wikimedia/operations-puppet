# == Class: jupyterhub::db
# Set up mysql server for persisting user information
class jupyterhub::base {

  class { '::mysql::server':
      config_hash => {
          'datadir'      => '/srv/mysql',
          'bind_address' => '127.0.0.1',
      },
  }
}
