# SPDX-License-Identifier: Apache-2.0
# @summary Installs a local NRPE plugin
# @param source a puppet Source to the script file
# @param content String content of the script
# @param ensure whether this script should be present or not
define nrpe::plugin (
    Optional[Stdlib::Filesource] $source  = undef,
    Optional[String]             $content = undef,
    Wmflib::Ensure               $ensure  = present,
) {
    if $ensure == 'present' and $source == undef and $content == undef {
        fail('Either source or content attribute needs to be given')
    }
    if $source != undef and $content != undef {
        fail('Both source and content attribute have been defined')
    }

    @file { "/usr/local/lib/nagios/plugins/${title}":
        ensure  => stdlib::ensure($ensure, 'file'),
        source  => $source,
        content => $content,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        tag     => 'nrpe::plugin',
    }
}
