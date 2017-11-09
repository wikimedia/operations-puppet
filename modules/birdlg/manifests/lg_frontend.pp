# == Class: librenms
#
# This class installs & manages bird-lg frontend
#
class birdlg::lg_frontend(
    $session_key,     #TODO
    $install_dir='/srv/deployment/birdlg/',
) {


  package { [
          'python-flask',
          'python-dnspython',
          'python-pydot',
          'python-memcache',
          'graphviz',
      ]:
      ensure => present,
  }

  file { "${install_dir}/lg.cfg":
      ensure  => present,
      owner   => 'bird',
      group   => 'bird',
      mode    => '0440',
      content => template('birdlg/lg.cfg.erb'),
  }

}
