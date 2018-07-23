define elasticsearch::curator::config(
    Wmflib::Ensure $ensure  = present,
    Optional[String] $content = undef,
    Optional[String] $source  = undef,
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
