# SPDX-License-Identifier: Apache-2.0
# Manage Pyrra filesystem operator configs
#

define pyrra::filesystem::config (
    Wmflib::Ensure   $ensure     = 'present',
    Optional[String] $source     = undef,
    Optional[String] $content    = undef,
    Stdlib::Unixpath $config_dir = '/etc/pyrra/config',
) {
    include pyrra::filesystem

    # The pyrra config includes glob $rules_dir/*.yaml, so require a .yaml file extension
    if $title !~ '.yaml$' {
        fail("Title(${title}): pyrra filesystem configs must have a .yaml file extention")
    }

    file { "${config_dir}/${title}":
        ensure  => file,
        mode    => '0444',
        owner   => 'root',
        source  => $source,
        content => $content,
    }
}
