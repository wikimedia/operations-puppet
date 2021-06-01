class mailman (
    Stdlib::Fqdn $lists_servername,
    Hash[String, String] $renamed_lists,
    Optional[String] $acme_chief_cert = undef,
){

    class { '::mailman::webui':
        lists_servername => $lists_servername,
        acme_chief_cert  => $acme_chief_cert,
        renamed_lists    => $renamed_lists,
    }
}
