class mediawiki::tlsproxy::yaml_defs (
  Stdlib::Unixpath $path,
  Optional[Array[String]] $listeners,
) {
  file { $path:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    content => ordered_yaml({'discovery' => {'listeners' => $listeners}}),
    mode    => '0444',
  }
}
