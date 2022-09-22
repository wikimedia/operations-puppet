# SPDX-License-Identifier: Apache-2.0
# == Define: debconf::set
#
# Sets a debconf value, useful for preseeding package configuration before
# installing them.
#
# === Parameters
#
# [*title*]
#   debconf question, e.g. mailman/used_languages
#
# [*value*]
#   preseeded answer to the debconf question
#
# [*type*]
#   type of the value to set.
#   Default: string
#
# [*owner*]
#   'Owner' of the debconf setting, this should usually be the package name.
#   For historical reasons, this is 'set', as this was incorrectly used as the 'owner'
#   for all usages of this define.  In order to not break those existent usages,
#   this value defaults to 'set'.  If you are using this define for a new setting,
#   please set $owner to the package name the setting is for.
#
define debconf::set(
    $value,
    $type = 'string',
    $owner = 'set'
) {
    exec { "debconf-set-selections set ${type} ${title}":
        path    => '/usr/bin:/usr/sbin:/bin:/sbin',
        command => "echo ${owner} ${title} ${type} \"${value}\" | debconf-set-selections",
        unless  => "test \"$(echo get ${title} | debconf-communicate)\" = \"0 ${value}\"",
    }
}
