# == Define: diamond::collector
#
# Diamond Collectors are Python modules that run within the Diamond
# process, collecting metrics about some subsystem, and feeding these
# metrics into Diamond for aggregation and reporting.
#
# If you are familiar with Ganglia, you can think of Collectors as
# being Diamond's answer to gmond modules.
#
# === Parameters
#
# [*ensure*]
#   Specifies whether or not to configure Diamond to use this collector.
#   May be 'present' or 'absent'. The default is 'present'.
#
# [*name*]
#   The name of the collector class. The 'Collector' suffix may be
#   omitted from the name.
#
# [*settings*]
#   A hash of configuration settings for the collector.
#   The 'enabled' setting is set to true by default.
#
# [*source*]
#   A Puppet file reference to the Python collector source file. This parameter
#   may be omitted if the collector is part of the Diamond distribution. It
#   should only be set for custom collectors. Unset by default.
#
# [*content*]
#   Content to be rendered as a custom collector Python module.  You may
#   use this instead of source if you need to render your Python code
#   using an ERb template.  This is useful if you need to install
#   multiple collectors that use the same Python code, since Diamond
#   forces you to associate collector configuration with Python Collector
#   subclasses by file name.  E.g.
#       /etc/diamond/collectors/CPUCollector.conf <-> /usr/share/diamond/collectors/cpu/cpu.py (CPUCollector)
#
# === Examples
#
# Configure an Nginx metric collector:
#
#  diamond::collector { 'Nginx':
#    source   => 'puppet:///modules/nginx/nginx-collector.py',
#    settings => {
#      req_host => 'gdash.wikimedia.org',
#      req_path => '/status',
#    },
#  }
#
# Configure a CPU utilization metric collector:
#
#  diamond::collector { 'CPU':
#    settings => {
#      percore   => false,
#      normalize => true,
#    },
#  }
#
define diamond::collector(
    $settings    = undef,
    $ensure      = present,
    $source      = undef,
    $content     = undef,
) {
    validate_ensure($ensure)

    require ::diamond

    $collector = regsubst($name, '(Collector)?$', 'Collector')

    file { "/etc/diamond/collectors/${collector}.conf":
        ensure  => $ensure,
        content => template('diamond/collector.conf.erb'),
        require => File['/etc/diamond/collectors'],
        notify  => Service['diamond'],
    }

    # Install a custom diamond collector if $source or $content were provided.
    if $source or $content {
        file { "/usr/share/diamond/collectors/${name}":
            ensure => ensure_directory($ensure),
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
            force  => true,
        }
        file { "/usr/share/diamond/collectors/${name}/${name}.py":
            ensure => $ensure,
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            notify => Service['diamond'],
        }
        if $source {
            File["/usr/share/diamond/collectors/${name}/${name}.py"] {
                source => $source,
            }
        }
        elsif $content {
            File["/usr/share/diamond/collectors/${name}/${name}.py"] {
                content => $content,
            }
        }
    }
}
