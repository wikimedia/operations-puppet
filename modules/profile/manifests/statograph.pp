# @summary Installs statograph and configures systemd timer
#
# @param api_key the api key for statuspage.io
# @param page_id the statuspage "page id" for the WMF main page
# @param ensure the ensureable parameter
# @param owner all files created by this module will be owned by this user
# @param group all files created by this module will be owned by this group
# @param mode all files created by this module will be managed with this mode

class profile::statograph (
    Wmflib::Ensure                  $ensure  = lookup('profile::statograph::ensure'),
    Sensitive[String[1]]            $api_key = lookup('profile::statograph::api_key'),
    Sensitive[String[1]]            $page_id = lookup('profile::statograph::page_id'),
    String                          $owner   = lookup('profile::statograph::owner'),
    String                          $group   = lookup('profile::statograph::group'),
    Stdlib::Filemode                $mode    = lookup('profile::statograph::mode'),
    Hash[String, Statograph::Proxy] $proxies = lookup('profile::statograph::proxies'),
    Array[Statograph::Metric]       $metrics = lookup('profile::statograph::metrics'),
){
    class {'statograph':
        ensure  => $ensure,
        api_key => $api_key,
        page_id => $page_id,
        owner   => $owner,
        group   => $group,
        mode    => $mode,
        proxies => $proxies,
        metrics => $metrics,
    }
}
