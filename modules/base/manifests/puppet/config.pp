# Definition base::puppet::config
# Populate a puppet config file and notify the compilation process
define base::puppet::config(
        $ensure='present',
        $prio=10,
        $content=undef,
        $source=undef,
) {
    if $source == undef and $content == undef  {
        fail('you must provide either "source" or "content"')
    }
    $title_safe = regsubst($title, '[\W_]', '-', 'G')
    $conf_file = sprintf('%02d-%s.conf', $prio, $title_safe)

    file { "/etc/puppet/puppet.conf.d/${conf_file}":
        ensure  => $ensure,
        content => $content,
        source  => $source,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Exec['compile puppet.conf'],
    }
}
