# SPDX-License-Identifier: Apache-2.0
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
# - $kubernetes_clusters: For each cluster to be monitored, its name and the path to a kubeconfig file.
# - $ensure: Whether to run the image catalog. Should be "present" only on the active deployment host.
class imagecatalog(
    Stdlib::Port $port,
    Stdlib::Unixpath $data_dir,
    Array[Tuple[String, Stdlib::Unixpath]] $kubernetes_clusters,
    Wmflib::Ensure $ensure,
) {
  ensure_packages(['gunicorn3', 'python3-imagecatalog'])

  systemd::sysuser { 'imagecatalog':
      home_dir => '/var/lib/imagecatalog',
      shell    => '/bin/bash',
  }

  file { $data_dir:
      ensure => directory,
      owner  => 'imagecatalog',
      group  => 'imagecatalog',
      mode   => '0770',
  }

  $db_path = "${data_dir}/catalog.sqlite"

  exec { 'create_empty_db_when_missing':
      command => "/usr/bin/imagecatalog --database=${db_path} init",
      creates => $db_path,
      user    => 'imagecatalog',
  }

  systemd::service { 'imagecatalog':
      ensure  => $ensure,
      content => systemd_template('imagecatalog'),
      restart => true,
  }

  profile::auto_restarts::service { 'imagecatalog':
      ensure => $ensure,
  }

  $clusters_flag = $kubernetes_clusters.map |$cluster| {
      $name = $cluster[0]
      $config_path = $cluster[1]
      "${name}:${config_path}"
  }.join(',')

  systemd::timer::job { 'imagecatalog_record':
      ensure      => $ensure,
      description => 'update the image catalog with all images running in prod',
      command     => "/usr/bin/imagecatalog --database=${db_path} --clusters=${clusters_flag} record",
      interval    => {
          start    => 'OnUnitActiveSec',
          interval => '1h',
      },
      user        => 'imagecatalog',
  }

  # TODO: Systemd timer to sync data dir from active to passive hosts
}
