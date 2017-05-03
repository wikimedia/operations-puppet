# == Definition: interface::enid

# Define used to populate /etc/network/interfaces.d
# This definition assumes that the user wants full control of the interface
# configuration and does not try to provide abstractions around the various
# things most other structures in the interface module do. Also by default it
# will NOT try to also set the currently active state to the configured one,
# that is by default it will NOT do an ifdown/ifup
#
# === Parameters
#  [*content*]
#    A string that will be /etc/network/interfaces.d/${title}'s content. It is
#    not possible to pass both content and source.
#  [*source*]
#    A path to a file that will be /etc/network/interfaces.d${title}'s content.
#    It is not possible to pass both content and source.
#  [*ifdownup*]
#    A boolean value whether changes in the configuration will cause a down and
#    then an up of the interface to apply new configuration. Defaults to false.
#    NOTE: Make sure you need this before specifying, it can have unexpected
#    consequences
#  [*ensure*]
#    Defaults to present.
define interface::enid(
    $content = undef,
    $source = undef,
    $ifdownup = false,
    $ensure = 'present',
){
    if !os_version('debian >= jessie') {
        fail('interface is supported only on debian systems since jessie')
    }
    if $source and $content {
        fail('interface: Defining both content and source is not allowed')
    }
    if !$source and !$content {
        fail('interface: Leaving both content and source undefined is not allowed')
    }
    file { "/etc/network/interfaces.d/${title}":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => $content,
        source  => $source,
    }

    if $ifdownup {
        exec { "ifdownup-${title}":
            command     => "/sbin/ifdown ${title} ; /sbin/ifup ${title}",
            subscribe   => File["/etc/network/interfaces.d/${title}"],
            refreshonly => true,
        }
    }
}
