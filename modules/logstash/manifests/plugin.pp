# == Define: logstash::plugin
#
# Provision a Logstash plugin.
#
# == Parameters:
# [*ensure*]
#   What state the plugin should be in. Default: present
#
# [*plugin*]
#   Plugin name. Default: $title
#
# [*gem*]
#   Path to local gem file for plugin. Default: undef
#
# == Example:
# logstash::plugin { 'logstash-filter-prune':
#     ensure => 'present',
#     gem    => '/srv/deployment/logstash/plugins/logstash-filter-prune-0.1.5.gem',
# }
define logstash::plugin (
    $ensure = 'present',
    $plugin = $title,
    $gem    = undef,
) {

    if $ensure == 'present' {
        $source = $gem ? {
            undef   => $plugin,
            default => $gem,
        }
        exec { "logstash_plugin_install_${title}":
            command => "/opt/logstash/bin/plugin install ${source}",
            unless  => "/opt/logstash/bin/plugin list --installed | grep -q ${plugin}",
            user    => 'root',
        }
    } else {
        exec { "logstash_plugin_uninstall_${title}":
            command => "/opt/logstash/bin/plugin uninstall ${source}",
            onlyif  => "/opt/logstash/bin/plugin list --installed | grep -q ${plugin}",
            user    => 'root',
        }
    }
}
# vim:sw=4:ts=4:sts=4:et:
