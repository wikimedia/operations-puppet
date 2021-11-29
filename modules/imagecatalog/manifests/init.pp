# == Class: imagecatalog
#
# Installs the OCI image catalog.
#
# TODO: For now, this assumes a singly-homed deployment model; we'll install on both deploy hosts
# but only use deploy1002. Soon it'll instead be active-passive behind a service hostname.
#
# == Parameters
# - $port: Port for web serving.
# - $data_dir: Path to a directory for the sqlite database. Directory is managed by this module.
# - $kubernetes_configs: List of paths to kubeconfig files, one for each cluster to be monitored.
class imagecatalog(
    Stdlib::Port $port,
    Stdlib::Unixpath $data_dir,
    Array[Stdlib::Unixpath] $kubernetes_configs,
) {
  ensure_packages(['gunicorn3', 'python3-imagecatalog'])

  group { 'imagecatalog':
      ensure => present,
      system => true,
  }

  user { 'imagecatalog':
      gid        => 'imagecatalog',
      shell      => '/bin/bash',
      system     => true,
      managehome => true,
      home       => '/var/lib/imagecatalog',
  }

  file { $data_dir:
      ensure => directory,
      owner  => 'imagecatalog',
      group  => 'imagecatalog',
      mode   => '0440',
  }

  $db_path = "${data_dir}/catalog.sqlite"

  exec { 'create_empty_db_when_missing':
      command => "/usr/bin/imagecatalog --database=${db_path} init",
      creates => $db_path,
      user    => 'imagecatalog',
  }

  systemd::service { 'imagecatalog':
      ensure  => present,
      content => systemd_template('imagecatalog'),
      restart => true,
  }

  # TODO: Hourly systemd timer to scan for what's currently running (as root, in order to use the admin k8s configs).
  # TODO: Systemd timer to sync data dir from active to passive hosts
}
