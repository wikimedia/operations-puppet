# SPDX-License-Identifier: Apache-2.0
# sonofgridengine/collector.pp

define sonofgridengine::collector(
    $dir,
    $sourcedir,
    $rname   = $title,
    $config  = undef,
    $etcdir  = '/var/lib/gridengine/etc',
) {

    $conf    = "${etcdir}/${dir}/${rname}"
    $dotfile = "${etcdir}/${dir}/.${rname}"
    $tracker = "${etcdir}/tracker/${dir}/${rname}"

    file { $dotfile:
        ensure  => file,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0664',
        content => template($config),
    }

    exec { "collect-${rname}-resource":
        command => "${etcdir}/bin/collector '${rname}' '${sourcedir}' '${dotfile}' '${conf}'",
        require => File[$dotfile],
    }
}
