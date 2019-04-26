class profile::standard(
    Boolean $has_default_mail_relay = lookup('profile::standard::has_default_mail_relay', {'default_value' => true}),
    Boolean $has_admin              = lookup('profile::standard::has_admin',              {'default_value' => true}),
    Array[String] $monitoring_hosts = lookup('monitoring_hosts',                          {'default_value' => []}),
) {
    class { '::standard':
        has_default_mail_relay => $has_default_mail_relay,
        has_admin              => $has_admin,
        monitoring_hosts       => $monitoring_hosts,
    }
}
