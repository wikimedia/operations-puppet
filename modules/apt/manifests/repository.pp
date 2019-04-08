define apt::repository(
    Optional[Stdlib::HTTPUrl]  $uri         = undef,
    Optional[String]           $dist        = undef,
    Optional[String]           $components  = undef,
    Boolean                    $source      = true,
    Boolean                    $comment_old = false,
    Optional[Stdlib::Unixpath] $keyfile     = undef,
    Enum['present','absent']   $ensure      = present,
    Boolean                    $trust_repo  = false,
) {
    if $ensure == 'present' and ! ($uri and $dist and $components) {
      fail('uri, dist and component are all required if ensure =>  present')
    }
    if $trust_repo {
        $trustedline = '[trusted=yes] '
    } else {
        $trustedline = ''
    }

    $binline = "deb ${trustedline}${uri} ${dist} ${components}\n"
    $srcline = $source ? {
        true    => "deb-src ${trustedline}${uri} ${dist} ${components}\n",
        default => '',
    }

    file { "/etc/apt/sources.list.d/${name}.list":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "${binline}${srcline}",
        notify  => Exec['apt-get update'],
    }

    if $comment_old {
        $escuri = regsubst(regsubst($uri, '/', '\/', 'G'), '\.', '\.', 'G')
        $binre = "deb(-src)?\s+${escuri}\s+${dist}\s"

        # comment out the old entries in /etc/apt/sources.list
        exec { "apt-${name}-sources":
            command => "/bin/sed -ri '/${binre}/s/^deb/#deb/' /etc/apt/sources.list",
            creates => "/etc/apt/sources.list.d/${name}.list",
            before  => File["/etc/apt/sources.list.d/${name}.list"],
        }
    }

    if $keyfile {
        file { "/var/lib/apt/keys/${name}.gpg":
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0400',
            source  => $keyfile,
            require => File['/var/lib/apt/keys'],
            before  => File["/etc/apt/sources.list.d/${name}.list"],
        }

        exec { "/usr/bin/apt-key add /var/lib/apt/keys/${name}.gpg":
            subscribe   => File["/var/lib/apt/keys/${name}.gpg"],
            refreshonly => true,
        }
    }
}
