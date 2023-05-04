# SPDX-License-Identifier: Apache-2.0
#
# configuration file, output directories, and documentation
# for how to test a new dumps nfs share
class snapshot::dumps::nfstester(
    $user   = undef,
    $group  = undef,
    $homedir = undef,
) {
    # for nfs testing we place the xml dumps config file,
    # all dblists and other files under the home
    # directory of the user that runs the dumps

    $settingsdir = "${homedir}/nfs_test_settings"
    file { $settingsdir:
      ensure => 'directory',
      mode   => '0755',
      owner  => $user,
      group  => $group,
    }

    $confsdir = "${settingsdir}/confs"
    $dblistsdir = "${settingsdir}/dblists"

    # the stages directory will be left empty but it should be specified
    $stagesdir = "${settingsdir}/stages"

    $templsdir = "${settingsdir}/templs"
    file { [ $confsdir, $dblistsdir, $stagesdir,
      $templsdir ]:

      ensure => 'directory',
      mode   => '0755',
      owner  => $user,
      group  => $group,
    }

    # dir will be written in by the dumps process run by the user
    $cachedir = "${settingsdir}/cache"
    file { $cachedir:
      ensure => 'directory',
      mode   => '0755',
      owner  => $user,
      group  => $group,
    }

    # these wikis are small enough to be useful for testing but still have a little activity each week
    # so that revision prefetch testing and adds/changes dumps will work with them

    $testwikis = [ 'igwiki', 'olowiki', 'snwiki' ]
    $allwikis = join($testwikis, "\n")
    $allwikisdblist = "${dblistsdir}/all.dblist"
    file { $allwikisdblist:
        ensure  => 'present',
        path    => "${dblistsdir}/all.dblist",
        mode    => '0644',
        owner   => $user,
        group   => $group,
        content => "${allwikis}\n",
    }

    # these files can all be empty
    $privatedblist = "${dblistsdir}/privatewikis.dblist"
    $closeddblist = "${dblistsdir}/closedwikis.dblist"
    $skipdblist = "${dblistsdir}/skip.dblist"
    $skipmonitorlist = "${dblistsdir}/skipmonitor.dblist"

    file { [ $privatedblist, $closeddblist, $skipdblist, $skipmonitorlist ]:

        ensure  => 'present',
        mode    => '0644',
        owner   => $user,
        group   => $group,
        content => '',
    }

}
