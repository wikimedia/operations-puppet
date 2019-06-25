# == Class cdh::hadoop::ssl_config
#
# Renders ssl-server.xml and ssl-client.xml configs.
#
# == Parameters
#
#    [*config_directory*]
#      Full path of the directory under which the xml config
#      files needs to be stored.
#
#    [*ssl_server_config*]
#      TLS configuration properties for ssl-server.xml.erb.
#      Default: undef
#
#    [*ssl_client_config*]
#      TLS configuration properties for ssl-client.xml.erb.
#      Default: undef
#
class cdh::hadoop::ssl_config (
    $config_directory,
    $ssl_server_config = undef,
    $ssl_client_config = undef,
) {
    if $ssl_server_config {
        file { "${config_directory}/ssl-server.xml":
            owner   => 'hdfs',
            group   => 'hadoop',
            mode    => '0440',
            content => template('cdh/hadoop/ssl-server.xml.erb'),
        }
    }

    if $ssl_client_config {
        file { "${config_directory}/ssl-client.xml":
            owner   => 'yarn',
            group   => 'hadoop',
            mode    => '0444',
            content => template('cdh/hadoop/ssl-client.xml.erb'),
        }
    }
}