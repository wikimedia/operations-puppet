# == Base::service_sidekick ==
#
# Allows defining "systemd sidekicks" - i.e. units that bind their
# execution to another unit.
#
# It can be used instead of the ExecPreStart / ExecPostStop stanzas
# for operations that don't need to block spawning the service.
#
# Idea and naming are borrowed from CoreOS, see
# https://coreos.com/fleet/docs/latest/launching-containers-fleet.html#run-a-simple-sidekick
#
# We prefer convention over configuration, so this define will require
# you to respect those in order to work.
#
# === Paramenters ===
#
# [*ensure*]
#  Is the usual metaparameter, defaults to present. Valid values are 'present'
#  and 'absent'.
#
# [*parent*]
#  The parent unit we're linking this sidekick to. Should be the name of a
#  base::service_unit resource.
#
# [*start*]
#  The script to execute on start. If it doesn't start with an absolute path,
#  it will be executed with /bin/bash -c
#
# [*stop*]
#  The script to execute on stop. If it doesn't start with an absolute path,
#  it will be executed with /bin/bash -c
#
define base::service_sidekick (
    $parent,
    $start,
    $stop,
    $ensure = present,
)
{
    if $::initsystem != 'systemd' {
        fail('base::service_sidekick only works with systemd')
    }

    validate_ensure($ensure)

    # Depend on the parent service unit
    Base::Service_unit[$parent] -> Base::Service_sidekick[$title]

    $servname = "${parent}-sidekick-${title}"
    $path = "/lib/systemd/system/${servname}.service"

    file { $path:
        ensure  => $ensure,
        content => template('base/sidekick_service.erb'),
        mode    => '0444',
        owner   => root,
        group   => root,
    }

    exec { "systemd reload for ${servname}":
        refreshonly => true,
        command     => '/bin/systemctl daemon-reload',
        subscribe   => File[$path],
        notify      => Service[$servname],
    }

    service { $servname:
        ensure   => $ensure,
        provider => 'systemd'
    }
}
