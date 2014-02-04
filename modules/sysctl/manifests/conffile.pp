# == Define: sysctl::conffile
#
# Represents a file with sysctl kernel parameters in /etc/sysctl.d.
#
define sysctl::conffile(
    $ensure   = present,
    $file     = $title,
    $content  = undef,
    $source   = undef,
    $priority = 60
) {
    include sysctl

    $basename = regsubst($file, '\W', '-', 'G')
    file { "/etc/sysctl.d/${priority}-${basename}.conf":
        ensure  => $ensure,
        content => $content,
        source  => $source,
        notify  => Service['procps'],
    }
}
