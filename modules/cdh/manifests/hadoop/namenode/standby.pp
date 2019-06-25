# == Class cdh::hadoop::namenode::standby
# Hadoop Standby NameNode.  Include this class instead of
# cdh::hadoop::master on your HA standby NameNode(s).  This
# will bootstrap the standby dfs.name.dir with the contents
# from your primary active NameNode.
#
# See README.md for more documentation.
#
# NOTE: Your JournalNodes should be running before this class is applied.
#
class cdh::hadoop::namenode::standby(
    $use_kerberos = false,
    $excluded_hosts = [],
) {

    # Fail if nameservice_id isn't set.
    if (!$::cdh::hadoop::ha_enabled) {
        fail('Cannot use Standby NameNode in a non HA setup.  Specify journalnodes in the $journalnode_hosts parameter on the cdh::hadoop class to enable HA.')
    }

    class { 'cdh::hadoop::namenode':
        use_kerberos   => $use_kerberos,
        standby        => true,
        excluded_hosts => $excluded_hosts,
    }
}
