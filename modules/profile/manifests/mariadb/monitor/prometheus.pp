# mysql groups for monitoring
# * mysql_group (required): general usage of the server, for example:
#   - 'core': production mediawiki servers
#   - 'dbstore': servers for backup
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
class profile::mariadb::monitor::prometheus(
    $mysql_group,
    $mysql_role,
    $mysql_shard = '',
    $socket = '/run/mysqld/mysqld.sock',
    ) {

    include role::prometheus::node_exporter
    class { 'role::prometheus::mysqld_exporter':
        socket => $socket,
    }
}
