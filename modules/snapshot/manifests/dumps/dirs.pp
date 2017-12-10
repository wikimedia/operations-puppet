class snapshot::dumps::dirs(
    $user = undef,
    $xmldumpsmount = undef,
) {
    # need to create and manage these, and have them
    # available for a shell script that sets vars with
    # their values for inclusion by other scripts
    $dumpsdir = '/etc/dumps'
    file { $dumpsdir:
      ensure => 'directory',
      mode   => '0755',
      owner  => 'root',
      group  => 'root',
    }

    $confsdir = "${dumpsdir}/confs"
    $dblistsdir = "${dumpsdir}/dblists"
    $stagesdir = "${dumpsdir}/stages"
    $templsdir = "${dumpsdir}/templs"
    file { [ $confsdir, $dblistsdir, $stagesdir,
      $templsdir ]:

      ensure => 'directory',
      mode   => '0755',
      owner  => 'root',
      group  => 'root',
    }

    # dir will be written in by the user
    $cachedir = "${dumpsdir}/cache"
    file { $cachedir:
      ensure => 'directory',
      mode   => '0755',
      owner  => $user,
      group  => 'root',
    }

    # need these only for the shell script that sets
    # vars with their values for other scripts
    $xmldumpsdir = "${xmldumpsmount}/xmldatadumps"
    $cronsdir = "${xmldumpsmount}/otherdumps"
    $apachedir = '/srv/mediawiki'
    $repodir = '/srv/deployment/dumps/dumps/xmldumps-backup'

    # here's that script; it gets sourced by
    # various cron jobs so they know where to
    # write output, where to find dump scripts, etc.
    file { '/usr/local/etc/set_dump_dirs.sh':
        ensure  => 'present',
        path    => '/usr/local/etc/set_dump_dirs.sh',
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        content => template('snapshot/set_dump_dirs.sh.erb'),
    }
}
