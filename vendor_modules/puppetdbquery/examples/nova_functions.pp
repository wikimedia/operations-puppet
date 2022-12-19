# These examples use functions that ship with the
# puppetlabs-nova module

$rabbit_connection_hash = collect_rabbit_connection('fqdn', 'architecture=amd64')

notice("rabbit host: ${rabbit_connection_hash[host]}")
notice("rabbit port: ${rabbit_connection_hash[port]}")
notice("rabbit user: ${rabbit_connection_hash[user]}")
notice("rabbit password: ${rabbit_connection_hash[password]}")

notice(collect_nova_db_connection('fqdn', 'architecture=amd64'))

$vnc_proxy_host   = unique(query_nodes('Class[Nova::Vncproxy]', 'fqdn'))
notice("vnc proxy host ${vnc_proxy_host}")

# glance api servers
