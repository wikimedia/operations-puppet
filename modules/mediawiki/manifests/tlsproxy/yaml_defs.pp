class mediawiki::tlsproxy::yaml_defs (
  Stdlib::Unixpath $path,
  Optional[Array[String]] $listeners,
) {
  file { $path:
    ensure  => present,
    owner   => 'root',
    content => ordered_yaml({'discovery' => {'listeners' => $listeners}}),
    mode    => '0400',
    group   => 0400,
  }
}
