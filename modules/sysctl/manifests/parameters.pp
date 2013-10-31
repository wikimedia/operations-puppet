# == Define: sysctl::parameters
#
# This custom resource lets you specify sysctl parameters using a Puppet
# hash, set as the 'values' parameter.
#
define sysctl::parameters(
    $values,
    $ensure   = present,
    $file     = $title,
    $priority = '10'
) {
    sysctl::conffile { $file:
        ensure   => $ensure,
        content  => template('sysctl/sysctl.conf.erb'),
        priority => $priority,
    }
}
