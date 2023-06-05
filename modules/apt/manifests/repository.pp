define apt::repository(
    Optional[Stdlib::HTTPUrl]          $uri           = undef,
    Optional[String]                   $dist          = undef,
    Optional[String]                   $components    = undef,
    Boolean                            $bin           = true,
    Boolean                            $source        = true,
    Optional[Pattern[/\.(asc|gpg)\z/]] $keyfile       = undef,
    Optional[Stdlib::Unixpath]         $keyfile_path  = undef,
    Wmflib::Ensure                     $ensure        = present,
    Boolean                            $trust_repo    = false,
    Optional[Stdlib::Unixpath]         $concat_target = undef,
) {
    if $ensure == 'present' and ! ($uri and $dist and $components) {
      fail('uri, dist and component are all required if ensure =>  present')
    }

    if $keyfile and $keyfile_path {
        fail('Only one of keyfile and keyfile_path may be specified')
    }

    if $trust_repo {
        $kpath = undef
        $trustedline = '[trusted=yes] '
    } elsif $keyfile {
        $kpath = "/etc/apt/keyrings/${$keyfile.basename}"

        if !defined(File[$kpath]) {
            file { $kpath:
                ensure => stdlib::ensure($ensure, 'file'),
                owner  => 'root',
                group  => 'root',
                mode   => '0444',
                source => $keyfile,
                notify => Exec['apt-get update'],
            }
        }

        $trustedline = "[signed-by=${kpath}] "
    } elsif $keyfile_path {
        $kpath = $keyfile_path
        $trustedline = "[signed-by=${kpath}] "
    } else {
        $kpath = undef
        $trustedline = ''
    }

    if $source {
        $types = ['deb', 'deb-src']
    } else {
        $types = ['deb']
    }

    if debian::codename::ge('bookworm') {
        $deb_sources = epp('apt/sources-deb822.epp', {
            components => $components,
            keyfile    => $kpath,
            suites     => $dist,
            trust_repo => $trust_repo,
            types      => $types,
            url        => $uri,
        })

        if $concat_target {
            concat::fragment { $name:
                target  => $concat_target,
                content => "${deb_sources}\n",
            }
        } else {
            concat { "/etc/apt/sources.list.d/${name}.sources":
                ensure => present,
                owner  => 'root',
                group  => 'root',
                mode   => '0444',
                notify => Exec['apt-get update'],
            }
            concat::fragment { "${name}-header":
                target => "/etc/apt/sources.list.d/${name}.sources",
                order  => '01',
                source => 'puppet:///modules/apt/sources-deb822-header.txt',
            }
            concat::fragment { $name:
                target  => "/etc/apt/sources.list.d/${name}.sources",
                content => $deb_sources,
            }
        }
    } else {
        if $concat_target {
            fail('concat_target only supported on bookworm and newer.')
        }
        $binline = $bin ? {
            true    => "deb ${trustedline}${uri} ${dist} ${components}\n",
            default => '',
        }
        $srcline = $source ? {
            true    => "deb-src ${trustedline}${uri} ${dist} ${components}\n",
            default => '',
        }
        file { "/etc/apt/sources.list.d/${name}.list":
            ensure  => stdlib::ensure($ensure, 'file'),
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => "${binline}${srcline}",
            notify  => Exec['apt-get update'],
        }
    }
}
