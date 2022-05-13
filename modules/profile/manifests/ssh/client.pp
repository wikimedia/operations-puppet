# @summary class to managed ssh client config
# @param manage_ssh_keys indicate if we should manage the known_hosts file
# @param manage_ssh_config if true manage the /etc/ssh/ssh_config file,
#   most other parameters are only valid if this is true
# @param hash_known_hosts HashKnownHosts value
# @param gss_api_authentication GSSAPIAuthentication value
# @param gss_api_delegate_credentials GSSAPIDelegateCredentials value
# @param send_env list of environment variables to send
class profile::ssh::client (
    Boolean          $manage_ssh_keys              = lookup('profile::ssh::client::manage_ssh_keys'),
    Boolean          $manage_ssh_config            = lookup('profile::ssh::client::manage_ssh_config'),
    Boolean          $hash_known_hosts             = lookup('profile::ssh::client::hash_known_hosts'),
    Boolean          $gss_api_authentication       = lookup('profile::ssh::client::gss_api_authentication'),
    Boolean          $gss_api_delegate_credentials = lookup('profile::ssh::client::gss_api_delegate_credentials'),
    Array[String[1]] $send_env                     = lookup('profile::ssh::client::send_env'),
) {
    class { 'ssh::client':
        * => wmflib::dump_params(),
    }
}
