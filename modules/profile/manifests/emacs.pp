class profile::emacs(
  Boolean $disable_backup_files = lookup('profile::emacs::disable_backup_files', {default_value => true}),
){

  ensure_packages(['emacs-nox'])

  if $disable_backup_files {
    $ensure = 'present'
  } else {
    $ensure = 'absent'
  }

  file { '/etc/emacs/site-start.d/99disable-backup-files.el':
    ensure  => $ensure,
    content => ";; Puppet: Backup files are unwanted\n(setq make-backup-files nil)\n",
    require => Package['emacs-nox'],
  }
}
