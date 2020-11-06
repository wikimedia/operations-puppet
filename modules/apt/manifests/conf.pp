define apt::conf(
    String $key,
    Variant[String, Integer, Boolean] $value,
    Variant[String, Integer] $priority = '20',
    Enum['present', 'absent'] $ensure  = present,
) {
    if $value !~ Integer {
      $content = "${key} \"${value}\";\n"
    } else {
      $content = "${key} ${value};\n"
    }

    file { "/etc/apt/apt.conf.d/${priority}${name}":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => $content,
        notify  => Exec['apt-get update'],
    }
}
