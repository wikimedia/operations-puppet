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

}
