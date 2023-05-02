define apt::repository(
    Optional[Stdlib::HTTPUrl]          $uri         = undef,
    Optional[String]                   $dist        = undef,
    Optional[String]                   $components  = undef,
    Boolean                            $bin         = true,
    Boolean                            $source      = true,
    Boolean                            $comment_old = false,
    Optional[Pattern[/\.(asc|gpg)\z/]] $keyfile     = undef,
    Wmflib::Ensure                     $ensure      = present,
    Boolean                            $trust_repo  = false,
) {
    if $ensure == 'present' and ! ($uri and $dist and $components) {
      fail('uri, dist and component are all required if ensure =>  present')
    }
    if $trust_repo {
        $trustedline = '[trusted=yes] '
    } elsif $keyfile {
        $repo_key = $keyfile.basename

        ensure_resource('file', "/etc/apt/keyrings/${repo_key}", {
            ensure => stdlib::ensure($ensure, 'file'),
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            source => $keyfile,
            notify => Exec['apt-get update'], })

        $trustedline = "[signed-by=/etc/apt/keyrings/${repo_key}] "
    } else {
        $trustedline = ''
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
}
