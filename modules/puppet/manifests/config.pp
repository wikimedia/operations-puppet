# @summary Populate a puppet config file and notify the compilation process
# @param ensure the ensure parameter
# @param prio the config priority
# @param content the config content
# @param source the config source
define puppet::config(
    Wmflib::Ensure               $ensure  = 'present',
    Integer[0,99]                $prio    = 10,
    Optional[String[1]]          $content = undef,
    Optional[Stdlib::Filesource] $source  = undef,
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
