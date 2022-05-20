# SPDX-License-Identifier: Apache-2.0
# Manage Thanos recording rules
#

define thanos::recording_rule (
    Wmflib::Ensure   $ensure    = 'present',
    Optional[String] $source    = undef,
    Optional[String] $content   = undef,
    Stdlib::Unixpath $rules_dir = '/etc/thanos-rule/rules',
) {
    include thanos

    # The thanos config includes glob $rules_dir/*.yaml, so require a .yaml file extension
    if $title !~ '.yaml$' {
        fail("Title(${title}): thanos recording rules must have a .yaml file extention")
    }

    # Perform a rule validity check before deploying
    $validate_cmd = '/usr/bin/thanos tools rules-check --rules %'

    file { "${rules_dir}/${title}":
        ensure       => file,
        mode         => '0444',
        owner        => 'root',
        source       => $source,
        content      => $content,
        validate_cmd => $validate_cmd,
        notify       => Exec['reload thanos-rule'],
    }
}
