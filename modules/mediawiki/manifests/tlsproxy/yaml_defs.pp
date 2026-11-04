class mediawiki::tlsproxy::yaml_defs (
  Stdlib::Unixpath $path,
  Optional[Array[String]] $listeners,
) {
  $errorpage = mediawiki::errorpage_content({
    'footer' => '<p>Original error: %LOCAL_REPLY_BODY% </p>',
  })
  file { $path:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    content => stdlib::to_yaml({'discovery' => {'listeners' => $listeners}, 'mesh' => {'error_page' => $errorpage}}),
    mode    => '0444',
  }
}
