# Define additional Postfix settings.
#
# Any settings not (yet) implemented in the main class or per-transport
# settings can be defined here.
#
# @example An example setting
#   include postfix
#   postfix::main { 'dovecot_destination_recipient_limit':
#     value => 1,
#   }
#
# @param value
# @param setting
# @param ensure
#
# @see puppet_classes::postfix postfix
# @see puppet_defined_types::postfix::master postfix::master
#
# @since 1.0.0
define postfix::main (
  String                    $value,
  String                    $setting = $title,
  Enum['present', 'absent'] $ensure  = 'present',
) {

  include postfix

  postfix_main { $setting:
    ensure  => $ensure,
    value   => $value,
    target  => "${postfix::conf_dir}/main.cf",
    require => Class['postfix::config'],
    notify  => Class['postfix::service'],
  }
}
