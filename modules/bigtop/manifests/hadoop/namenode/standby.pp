# SPDX-License-Identifier: Apache-2.0
# == Class bigtop::hadoop::namenode::standby
# Hadoop Standby NameNode.  Include this class instead of
# bigtop::hadoop::master on your HA standby NameNode(s).  This
# will bootstrap the standby dfs.name.dir with the contents
# from your primary active NameNode.
#
# See README.md for more documentation.
#
# NOTE: Your JournalNodes should be running before this class is applied.
#
class bigtop::hadoop::namenode::standby(
    $excluded_hosts = [],
) {

    # Fail if nameservice_id isn't set.
    if (!$::bigtop::hadoop::ha_enabled) {
        fail('Cannot use Standby NameNode in a non HA setup.  Specify journalnodes in the $journalnode_hosts parameter on the bigtop::hadoop class to enable HA.')
    }

    class { 'bigtop::hadoop::namenode':
        standby        => true,
        excluded_hosts => $excluded_hosts,
    }
}
