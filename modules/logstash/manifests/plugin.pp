# == Define: logstash::plugin
#
# A Logstash plugin.
#
# === Parameters
#
# [*title*]
#   Name of the plugin. Examples:
# logstash-filter-prune
#
define logstash::plugin(
    $ensure = present,
) {
    case $ensure {
        present: {
            # TODO: Untested. Alternate method is to use path.plugins config option,
            # but that is documented as an option for developers iterating on local
            # development of a plugin.
            $gem_file = "/srv/deployment/logstash/plugins/${title}.gem"
            exec { "install_logstash_plugin_${title}":
                command => "/usr/share/logstash/bin/logstash-plugin install '${gem_file}'",
                require => Package['logstash/plugins'],
                notify  => Service['logstash'],
                unless  => "grep '^gem \"${title}\"$' /usr/share/logstash/Gemfile"
            }
        }
        absent: {
            exec { "uninstall_logstash_plugin_${title}":
                command => "/usr/share/logstash/bin/logstash-plugin remove '${title}'",
                require => Package['logstash'],
                notify  => Service['logstash'],
                onlyif  => "grep '^gem \"${title}\"$' /usr/share/logstash/Gemfile"
            }
        }
        default: {
            fail("'ensure' must be 'present' or 'absent' (got: '${ensure}').")
        }
    }
}
