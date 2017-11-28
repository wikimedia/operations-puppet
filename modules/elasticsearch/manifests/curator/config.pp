define elasticsearch::curator::config(
    $ensure  = present,
    $content = undef,
    $source  = undef,
) {
    file { "/etc/curator/${title}.yaml":
        ensure  => $ensure,
        content => $content,
        source  => $source,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }

}