class base::resolving (
    Array[Stdlib::IP::Address] $nameservers,
    Array[Stdlib::Fqdn]        $domain_search              = [$facts['domain']],
    Array[Stdlib::Fqdn]        $labs_additional_domains    = [],
    Integer[1,30]              $timeout                    = 1,
    Integer[1,5]               $ndots                      = 1,
    Integer[1,5]               $attempts                   = 3,
    Optional[String]           $legacy_cloud_search_domain = undef,
){
    # TODO: move this to hiera
    if $::realm == 'labs' {
        $disable_resolvconf  = true
        $disable_dhcpupdates = true
        $_domain_search      = $legacy_cloud_search_domain.empty ? {
            true    => $domain_search,
            default => $domain_search + ["${::labsproject}.${legacy_cloud_search_domain}", $legacy_cloud_search_domain],
        }
    } else {
        $disable_resolvconf  = false
        $disable_dhcpupdates = false
        $_domain_search      = $domain_search
    }
    # Ignoring, will convert this to a profile shortly
    class {'resolvconf':  # lint:ignore:wmf_styleguide
        domain_search       => $_domain_search,
        nameservers         => $nameservers,
        timeout             => $timeout,
        attempts            => $attempts,
        ndots               => $ndots,
        disable_resolvconf  => $disable_resolvconf,
        disable_dhcpupdates => $disable_resolvconf,
    }

}
