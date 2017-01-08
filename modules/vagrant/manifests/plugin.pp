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

    Exec {
        user        => 'mwvagrant',
        cwd         => $::vagrant::vagrant_home,
        environment => "VAGRANT_HOME=${::vagrant::vagrant_home}",
    }

    if $ensure == 'present' {
        exec { "install_vagrant_plugin_${title}":
            command => "/usr/bin/vagrant plugin install ${plugin}",
            unless  => "/usr/bin/vagrant plugin list | /bin/grep -q ${plugin}",
        }
    } else {
        exec { "uninstall_vagrant_plugin_${title}":
            command => "/usr/bin/vagrant plugin uninstall ${plugin}",
            onlyif  => "/usr/bin/vagrant plugin list | /bin/grep -q ${plugin}",
        }
    }
}
