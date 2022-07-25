# @summary class to managed ssh client config
# @param manage_ssh_keys indicate if we should manage the known_hosts file
# @param manage_ssh_config if true manage the /etc/ssh/ssh_config file,
#   most other parameters are only valid if this is true
# @param hash_known_hosts HashKnownHosts value
# @param gss_api_authentication GSSAPIAuthentication value
# @param gss_api_delegate_credentials GSSAPIDelegateCredentials value
# @param send_env list of environment variables to send
# @param known_hosts a hash of known_hosts most likley generated from puppetdb
class ssh::client (
    Boolean          $manage_ssh_keys              = true,
    Boolean          $manage_ssh_config            = true,
    Boolean          $hash_known_hosts             = true,
    Boolean          $gss_api_authentication       = true,
    Boolean          $gss_api_delegate_credentials = false,
    Array[String[1]] $send_env                     = ['LANG', 'LC_*'],
    Hash             $known_hosts                  = {}
) {
    ensure_packages('openssh-client')

    if $manage_ssh_keys and $::use_puppetdb {
        file { '/etc/ssh/ssh_known_hosts':
            ensure  => file,
            content => template('ssh/known_hosts.erb'),
            backup  => false,
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
        }
    }
    if $manage_ssh_config {
        file { '/etc/ssh/ssh_config':
            ensure  => file,
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            content => template('ssh/ssh_config.erb'),
        }
    }
}
