# == Define: kmod::module
#
# Make sure that the given kernel module is loaded (or not).
#
# === Parameters
#
# [*ensure*]
#   If 'present', the module will be loaded. If 'absent', unloaded.
#   The default is 'present'.
#
define kmod::module($ensure=present) {
    validate_ensure($ensure)

    if $ensure == 'present' {
        $modprobe_cmd = "/sbin/modprobe ${name}"
    } else {
        $modprobe_cmd = "/sbin/modprobe -r ${name}"
    }

    file { "/etc/modules-load.d/${name}.conf":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "${name}\n",
        notify  => Exec[$modprobe_cmd],
    }

    if $ensure == 'present' {
        exec { $modprobe_cmd:
            unless => "/bin/lsmod | /bin/grep -q '^${name} '",
            refreshonly => true,
        }
    } else {
        exec { $modprobe_cmd:
            onlyif => "/bin/lsmod | /bin/grep -q '^${name} '",
            refreshonly => true,
        }
    }
}
