# == Define: prometheus::rules
#
# Add a Prometheus 'recording rule', see also:
# https://prometheus.io/docs/querying/rules/
# https://prometheus.io/docs/practices/rules/
#
# = Parameters
#
# [*instance*]
#   The Prometheus instance the rule is for.
#
# [*instance_path*]
#   The Prometheus instance path on filesystem.

define prometheus::rule (
    String           $instance,
    Wmflib::Ensure   $ensure = 'present',
    Stdlib::Unixpath $instance_path = "/srv/prometheus/${instance}",
    Optional[String] $source = undef,
    Optional[String] $content = undef,
) {

    $service_name = "prometheus@${instance}"
    $file_path = "${instance_path}/rules/${title}"

    if $title !~ '.yml$' {
        fail("Title(${title}): must have a .yml extention")
    }
    $validate_cmd = '/usr/bin/promtool check rules %'

    file { $file_path:
        ensure       => file,
        mode         => '0444',
        owner        => 'root',
        source       => $source,
        content      => $content,
        notify       => Exec["${service_name}-reload"],
        validate_cmd => $validate_cmd,
    }
}
