# SPDX-License-Identifier: Apache-2.0
# === Define logrotate::conf
#
# Thin helper for the definition of logrotate rules.
# It basically ensure consistency and that we don't risk things like
# https://phabricator.wikimedia.org/T127025 to happen again
#
define logrotate::conf (
    $ensure = present,
    $source = undef,
    $content = undef,
) {

    file { "/etc/logrotate.d/${title}":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => $source,
        content => $content,
    }
}
