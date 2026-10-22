# SPDX-License-Identifier: Apache-2.0
# @summary PHP security mitigations
#
# @param sapis The list of PHP SAPIs to apply the mitigations to. Defaults to ['cli'].
# @param php_version The PHP version to apply the mitigations to. Defaults to the system's Debian PHP version.

define php::mitigations (
    Array[Php::Sapi] $sapis  = ['cli'],
    Optional[String] $php_version = undef,
    Boolean $restart = true,
) {
    $version = $php_version ? {
        undef   => wmflib::debian_php_version(),
        default => $php_version,
    }

    file { "/etc/php/${version}/mods-available/mitigations.ini":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => wmflib::php_ini({
                'session.upload_progress.enabled' => 0,
        }),
        notify  => Exec["phpenmod mitigations for ${version}"],
    }
    exec { "phpenmod mitigations for ${version}":
        command     => "phpenmod -v ${version} -s ALL mitigations",
        path        => '/usr/bin:/usr/sbin:/bin:/sbin',
        creates     => "/etc/php/${version}/${sapis[0]}/conf.d/20-mitigations.ini",
        refreshonly => true,
    }
    if 'fpm' in $sapis {
        if $restart {
            Exec["phpenmod mitigations for ${version}"] ~> Service["php${version}-fpm"]
        }
    }
    if 'apache2' in $sapis {
        if $restart {
            Exec["phpenmod mitigations for ${version}"] ~> Service['apache2']
        }
    }
}
