# Sysctl settings

# Define: sysctlfile
#
# Creates a file in /etc/sysctl.d to set sysctl settings, and reloads
# sysctl with the new settings.
#
# There are three ways to use this define.  You must specify one of
# $value, $content, or $source.  Not specifying one of these results
# in a parse failure.
#
# Usage 1: $value
#    sysctl { "net.core.rmem_max": value => 16777218 }
#
# Usage 2: $content
#    $rmem_max = 536870912
#    sysctl { "custom_rmem_max": content => template("sysctl/sysctl_rmemmax.erb") }
#
# Usage 3: $source
#    sysctl { "custom_rmem_max": source => "puppet:///files/misc/rmem_max.sysctl.conf" }
#
# Parameters:
#    $key
#    $value         - Puts "$key = $value" in the sysctl.d file.
#    $content       - Puts this exact content in the sysctl.d file.
#    $source        - Puts the $source file at the sysctl.d file.
#    $ensure        - Either 'present' or 'absent'.  Default: 'present'.
#    $number_prefix - The load order prefix number in the sysctl.d filename.  Default '60'.  You probably don't need to change this.
#
define sysctlfile($value         = undef,
                  $key           = $title,
                  $content       = undef,
                  $source        = undef,
                  $ensure        = 'present',
                  $number_prefix = "60") {
    $sysctl_file = "/etc/sysctl.d/${number_prefix}-${key}.conf"

    file { $sysctl_file:
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        ensure => $ensure,
    }

    # if using $value, then set $key = $value in the sysctl.d file
    if $value {
        File[$sysctl_file] { content => "${key} = ${value}" }
    }
    # else just set the content
    elsif $content {
        File[$sysctl_file] { content => $content }
    }
    # else put the file in place from a source file.
    elsif $source {
        File[$sysctl_file] { source  => $source }
    }
    # if none of the above are defined, then throw a parse failure.
    else {
        fail("sysctl '${title}' must specify one of \$content, \$source or \$value.")
    }

    # Refresh sysctl if we are ensuring the sysctl.d file
    # exists.  NOTE:  I'm not sure how to reset the sysctl
    # value to its original if we ensure => absent.  For now,
    # that will have to wait until a reboot happens.  This
    # probably won't be a real problem anyway.  Anyone
    # using this define can just explicitly set the value
    # back to what it should be, rather than using ensure => 'absent'.
    if $ensure == 'present' {
        # refresh sysctl when the sysctl file changes
        exec { "sysctl_reload_${key}":
            command     => "/sbin/sysctl -p $sysctl_file",
            subscribe   => File[$sysctl_file],
            refreshonly => true,
        }
    }

    if !($::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "10.04") >= 0) {
        alert("Distribution on $hostname does not support /etc/sysctl.d/ files yet.")
    }
}
