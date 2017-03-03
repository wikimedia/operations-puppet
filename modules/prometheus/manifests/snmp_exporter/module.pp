# === Parameters
#
# [*$title*]
#  The module name snmp_exporter should use, it needs to be passed on the url.
#
# [*$template*]
#  Which template to use for this module.
#
# [*$community*]
#  If defined, the SNMPv2c community to use.

define prometheus::snmp_exporter::module (
  $template,
  $community = undef,
  $ensure = present,
) {
    $module_name = $title

    # prometheus-snmp-exporter-config will take care of assembling all
    # modules yaml files into snmp.yml for snmp_exporter to consume.
    file { "/etc/prometheus/snmp.yml.d/${module_name}.yml":
        contents => template("prometheus/snmp_exporter/${template}.yml.erb"),
        notify   => Exec['prometheus-snmp-exporter-config'],
    }
}
