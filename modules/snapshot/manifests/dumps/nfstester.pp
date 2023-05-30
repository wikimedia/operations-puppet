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

    $nfstestingdir = "${homedir}/nfs_testing"
    file { $nfstestingdir :
      ensure => 'directory',
      mode   => '0755',
      owner  => $user,
      group  => $group,
    }

    $confsdir = "${nfstestingdir}/confs"
    $dblistsdir = "${nfstestingdir}/dblists"

    # the stages directory will be left empty but it should be specified
    $stagesdir = "${nfstestingdir}/stages"

    $templsdir = "${nfstestingdir}/templs"
    file { [ $confsdir, $dblistsdir, $stagesdir,
      $templsdir ]:

      ensure => 'directory',
      mode   => '0755',
      owner  => $user,
      group  => $group,
    }

    # dir will be written in by the dumps process run by the user
    $cachedir = "${nfstestingdir}/cache"
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

    $mountpoint = '/mnt/dumpsdatatest'
    $nfstestdir = "${mountpoint}/nfstest"
    $dumpstree = "${nfstestdir}/xmldatadumps"
    $otherdumpsdir = "${nfstestdir}/otherdumps"
    $publicdir = "${dumpstree}/public"
    $privatedir = "${dumpstree}/private"
    $tempdir = "${dumpstree}/temp"

    # the nfs share to be tested will be manually mounted. after that, we
    # want to run a script to create all the needed directories over there
    # if they do not exist from a previous test session.
    file { "${nfstestingdir}/test_outputdir_paths.sh":
      ensure  => 'present',
      mode    => '0755',
      owner   => $user,
      group   => $group,
      content => template('snapshot/dumps/nfs_testing/test_outputdir_paths.sh.erb'),
    }

    file {"${nfstestingdir}/nfs_testing_create_output_dirs.sh":
      ensure => 'present',
      mode   => '0755',
      owner  => $user,
      group  => $group,
      source => 'puppet:///modules/snapshot/dumps/nfs_testing/create_output_dirs.sh',
    }

    # set up a custom xml dups conf file for this testing, using the
    # custom outpuit paths and db lists and so on
    file { "${confsdir}/xmldumps.conf":
      ensure  => 'present',
      mode    => '0755',
      owner   => $user,
      group   => $group,
      content => template('snapshot/dumps/nfs_testing/nfstester_xmldumps.conf.erb')
    }

    # add documentation on how to test, since many commands must be run
    # manually; at least we won't have to look them up each time.
    file { "${nfstestingdir}/README_nfstesting.txt":
      ensure  => 'present',
      mode    => '0444',
      owner   => $user,
      group   => $group,
      content => template('snapshot/dumps/nfs_testing/README_nfstesting.txt.erb'),
    }

}
