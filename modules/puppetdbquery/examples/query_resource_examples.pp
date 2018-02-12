#
# I need to be able to query for how to connect to things:


# I need to query the following things
#   sql_connection
#     mysql://nova:${nova_db_password}@${controller_node_internal}/nova
#   rabbit_host
#   rabbit_password
#   rabbit_user

# for the rabbitmq host

# this syntax is a little strange ...
# it makes the resource look a little extraneous
$rabbit_resources = query_resource('Class[Nova::Rabbitmq]')

$rabbit_class      = $rabbit_resources['Class[Nova::Rabbitmq]']
$rabbit_params     = $rabbit_class['parameters']

# check that only one host has been found
$rabbit_host      = unique(query_nodes('Class[Nova::Rabbitmq]', 'fqdn') )
notice("rabbit host: ${rabbit_host}")

$rabbit_port      = $rabbit_params['port']
notice("rabbit port: ${rabbit_port}")
$rabbit_user      = $rabbit_params['userid']
notice("rabbit user: ${rabbit_user}")
$rabbit_password  = $rabbit_params['password']
notice("rabbit password: ${rabbit_password}")

# return the fqdn of the host that has applied
$vnc_proxy_host   = unique(query_nodes('Class[Nova::Vncproxy]', 'fqdn'))
notice("vnc proxy host ${vnc_proxy_host}")
# check the size of this thing and make some decisions

# figure out sql connection
$nova_db_host      = unique(query_nodes('Class[Nova::Db::Mysql]', 'fqdn'))
$nova_db_resources = query_resource('Class[Nova::Db::Mysql]', 'architecture=amd64')
$nova_db_class     = $nova_db_resources['Class[Nova::Db::Mysql]']
$nova_db_params    = $nova_db_class['parameters']
$nova_db_name      = $nova_db_params['dbname']
$nova_db_user      = $nova_db_params['user']
$nova_db_password  = $nova_db_params['password']

$nova_sql_conn = "mysql://${nova_db_user}:${nova_db_password}@${nova_db_host}/${nova_db_name}"

notice("nova sql connection: ${nova_sql_conn}")
