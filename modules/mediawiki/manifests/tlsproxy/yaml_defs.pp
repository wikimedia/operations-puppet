class mediawiki::tlsproxy::yaml_defs (
  Stdlib::Unixpath $path,
  Optional[Array[String]] $listeners,
) {
  $errorpage = mediawiki::errorpage_content({
    'footer'     => '<p>Original error: %LOCAL_REPLY_BODY% </p>',
    'margin'     => '7vw auto 0 auto', # Envoy can't accept % signs in its string formats AFAICS
    'margin_top' => '14vh'
  })
  file { $path:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    content => to_yaml({'discovery' => {'listeners' => $listeners}, 'mesh' => {'error_page' => $errorpage}}),
    mode    => '0444',
  }
}
