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
    $exporter_module = $title

    # prometheus-assemble-config will take care of assembling all
    # modules yaml files into snmp.yml for snmp_exporter to consume (init.pp)
    file { "/etc/prometheus/snmp.yml.d/${exporter_module}.yml":
        content   => template("prometheus/snmp_exporter/${template}.yml.erb"),
        show_diff => false,
        notify    => Exec['assemble snmp.yml'],
    }
}
