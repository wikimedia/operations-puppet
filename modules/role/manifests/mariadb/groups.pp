# mysql groups for monitoring and salt
# * mysql_group (required): general usage of the server, for example:
#   - 'core': production mediawiki servers
#   - 'dbstore': servers for backup and analytics
#   - 'labs': production and labs replicas of production
#   - 'misc': other services
# * mysql_shard (optional): for 'core', 'misc' and 'pc' services, vertical
#   slices:
#   - 's1': English Wikipedia (see dblists on mediawiki-config)
#   - 'm1': puppet, bacula, etc.
#   - most services are not segmented and will return the empty string ('')
# * mysql_role (required). One of three:
# - 'master': for the masters of each datacenter (one per shard and
#   datacenter). Only the one on the active datacenter is read-write of
#   all the ones on the same shard.
# - 'slave': for read-only slave
# - 'standalone': single servers that are not part of replication,
#   such as read-only 'es1' hosts; wikitech, or tendril

#FIXME: move node_exporter to standard and remove it from here when ready
class role::mariadb::groups(
    $mysql_group,
    $mysql_role,
    $mysql_shard = '',
    ) {

    salt::grain { 'mysql_group':
        ensure  => present,
        replace => true,
        value   => $mysql_group,
    }

    salt::grain { 'mysql_role':
        ensure  => present,
        replace => true,
        value   => $mysql_role,
    }

    if $mysql_shard != '' {
        salt::grain { 'mysql_shard':
            ensure  => present,
            replace => true,
            value   => $mysql_shard,
        }
    }

    # hacky workaround until we get rid of precise hosts
    # T123525
    if os_version('debian >= jessie || ubuntu >= trusty') {
        include role::prometheus::node_exporter
        include role::prometheus::mysqld_exporter
    }
}

