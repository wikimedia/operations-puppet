# == Define: sysctl::conffile
#
# Represents a Puppet-managed file with sysctl kernel parameters in
# /etc/sysctl.d/puppet-managed.
#
define sysctl::conffile(
    $ensure   = present,
    $file     = $title,
    $content  = undef,
    $source   = undef,
    $priority = '10',
) {
    include sysctl

    $basename = regsubst($file, '\W', '-', 'G')
    file { "/etc/sysctl.d/puppet-managed/${priority}-${basename}.conf":
        ensure  => $ensure,
        content => $content,
        source  => $source,
        notify  => Service['procps-puppet'],
    }
}
