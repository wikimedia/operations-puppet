class gitlab::restore(
  Wmflib::Ensure   $restore_ensure          = 'present',
  Stdlib::Unixpath $restore_dir_data        = '/srv/gitlab-backup',
){

  # install restore script
  file {"${restore_dir_data}/gitlab-restore.sh":
      ensure => $restore_ensure,
      mode   => '0744' ,
      owner  => 'root',
      group  => 'root',
      source => 'puppet:///modules/gitlab/gitlab-restore.sh';
  }
}
