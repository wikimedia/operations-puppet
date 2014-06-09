define dkim(
  $domain,
  $selector,
  $source=undef,
  $content=undef,
) {
    if $source != undef and $content != undef {
        fail('Both source and content attribute have been defined')
    }

    $keyfile = "/etc/exim4/dkim/${domain}-${selector}.key"

    file { $keyfile:
        ensure  => present,
        owner   => 'root',
        group   => 'Debian-exim',
        mode    => '0440',
        require => File['/etc/exim4/dkim'],
        notify  => Service['exim4'],
    }

    if $source != undef {
        File[$keyfile] {
            source => $source,
        }
    } elsif $content != undef {
        File[$keyfile] {
            content => $source,
        }
    } else {
        fail('Either source or content attribute needs to be given')
    }
}
