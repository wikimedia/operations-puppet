# == Class pybal::configuration
# Writes the pybal configuration to disk.
#
# Parameters:
# $services - hash of services that are present on this load-balancer
# lvs_class_hosts - comes from profile::lvs::configuration.
# config - wether to fetch the config from etcd or http
# global_options - pybal global options
# config_host - the fqdn:port for the host to get config from
# conftool_prefix - the prefix to use in queries to etcd
# ipip_enabled - whether IPIP encapsulation is enabled or not
class pybal::configuration(
    Hash[String, Wmflib::Service] $services,
    Hash $lvs_class_hosts,
    String $site,
    Enum['etcd', 'http'] $config='http',
    Hash $global_options={},
    String $config_host="config-master.${site}.wmnet",
    String $conftool_prefix = '/conftool/v1',
    Boolean $ipip_enabled = false,
) {

    # Generate PyBal config file
    file { '/etc/pybal/pybal.conf':
        require => Package['pybal'],
        content => template("${module_name}/pybal.conf.erb");
        # do not notify => Service['pybal'] on purpose
    }

}
