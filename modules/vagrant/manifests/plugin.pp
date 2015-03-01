# == Define: vagrant::plugin
#
# Provision a Vagrant plugin
#
# == Parameters:
# [*ensure*]
#   Whether the plugin should be installed. (default: present)
#
# [*plugin*]
#   Plugin name. (default: $title)
#
define vagrant::plugin (
    $ensure = 'present',
    $plugin = $title,
) {
    require ::vagrant

    if $ensure == 'present' {
        exec { "vagrant_plugin_${title}":
            command     => "/usr/bin/vagrant plugin install ${plugin}",
            unless      => "/usr/bin/vagrant plugin list | /bin/grep -q ${plugin}",
            user        => 'mwvagrant',
            environment => "VAGRANT_HOME=${::vagrant::vagrant_home}"
        }
    } else {
        exec { "vagrant_plugin_${title}":
            command     => "/usr/bin/vagrant plugin uninstall ${plugin}",
            onlyif      => "/usr/bin/vagrant plugin list | /bin/grep -q ${plugin}",
            user        => 'mwvagrant',
            environment => "VAGRANT_HOME=${::vagrant::vagrant_home}"
        }
    }
}
