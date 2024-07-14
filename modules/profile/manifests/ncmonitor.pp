# SPDX-License-Identifier: Apache-2.0
class profile::ncmonitor(
    String                    $acmechief_conf_path      = lookup('profile::ncmonitor::acmechief::conf_path'),
    String                    $acmechief_remote_url     = lookup('profile::ncmonitor::acmechief::remote_url'),
    String                    $dnsrepo_remote_url       = lookup('profile::ncmonitor::dnsrepo::remote_url'),
    String                    $dnsrepo_target_zone_path = lookup('profile::ncmonitor::dnsrepo::target_zone_path'),
    String                    $gerrit_ssh_key           = lookup('profile::ncmonitor::gerrit_ssh_key'),
    String                    $gerrit_ssh_key_path      = lookup('profile::ncmonitor::gerrit::ssh_key_path'),
    String                    $mm_api_pass              = lookup('profile::ncmonitor::markmonitor_api_password'),
    String                    $mm_api_user              = lookup('profile::ncmonitor::markmonitor_api_user'),
    Array[Stdlib::Host]       $nameservers              = lookup('profile::ncmonitor::nameservers'),
    String                    $ncredir_datfile_path     = lookup('profile::ncmonitor::ncredir::datfile_path'),
    String                    $ncredir_remote_url       = lookup('profile::ncmonitor::ncredir::remote_url'),
    Array[String]             $reviewers                = lookup('profile::ncmonitor::reviewers'),
    Stdlib::Absolutepath      $suffix_list_path         = lookup('profile::ncmonitor::suffix_list_path'),
    Optional[Stdlib::HTTPUrl] $http_proxy               = lookup('http_proxy'),
    Optional[String]          $gerrit_ssh_pubkey        = lookup('profile::ncmonitor::gerrit_ssh_pubkey'),
) {
    class { 'ncmonitor':
        acmechief_conf_path      => $acmechief_conf_path,
        acmechief_remote_url     => $acmechief_remote_url,
        dnsrepo_remote_url       => $dnsrepo_remote_url,
        dnsrepo_target_zone_path => $dnsrepo_target_zone_path,
        gerrit_ssh_key           => $gerrit_ssh_key,
        gerrit_ssh_key_path      => $gerrit_ssh_key_path,
        gerrit_ssh_pubkey        => $gerrit_ssh_pubkey,
        markmon_api_user         => $mm_api_user,
        markmon_api_pass         => $mm_api_pass,
        ncredir_datfile_path     => $ncredir_datfile_path,
        ncredir_remote_url       => $ncredir_remote_url,
        reviewers                => $reviewers,
        suffix_list_path         => $suffix_list_path,
        nameservers              => $nameservers,
        http_proxy               => $http_proxy,
        ensure                   => present,
    }

    class { 'ncmonitor::public_suffix_list':
        ensure     => present,
        http_proxy => $http_proxy,
    }

}
