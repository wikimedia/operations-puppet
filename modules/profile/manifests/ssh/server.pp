# @summary manage the ssh server daemon and config
# @param listen_port the port to listen on
# @param listen_addresses an array of addresses to listen on
# @param permit_root if true allow root logins
# @param authorized_keys_file space seperated list of authorized keys files
# @param authorized_keys_command command to run for authorized keys
# @param disable_nist_kex Allow uses to temporarily opt out of nist kex disabling
# @param explicit_macs Allow users to opt out of more secure MACs
# @param enable_hba enable host based authentication
# @param enable_kerberos enable kerberos
# @param disable_agent_forwarding disable agent forwarding
# @param challenge_response_auth Disable all password auth
# @param max_sessions allow users to override the maximum number ops sessions
# @param max_startups allow users to override the maximum number ops startups
# @param gateway_ports if true set sshd_config GatewayPorts to yes
class profile::ssh::server (
    Stdlib::Port                 $listen_port              = lookup('profile::ssh::server::listen_port'),
    Array[Stdlib::IP::Address]   $listen_addresses         = lookup('profile::ssh::server::listen_addresses'),
    Ssh::Config::PermitRootLogin $permit_root              = lookup('profile::ssh::server::permit_root'),
    Array[Stdlib::Unixpath]      $authorized_keys_file     = lookup('profile::ssh::server::authorized_keys_file'),
    Stdlib::Unixpath             $authorized_keys_command  = lookup('profile::ssh::server::authorized_keys_command'),
    Boolean                      $disable_nist_kex         = lookup('profile::ssh::server::disable_nist_kex'),
    Boolean                      $explicit_macs            = lookup('profile::ssh::server::explicit_macs'),
    Boolean                      $enable_hba               = lookup('profile::ssh::server::enable_hba'),
    Boolean                      $enable_kerberos          = lookup('profile::ssh::server::enable_kerberos'),
    Boolean                      $disable_agent_forwarding = lookup('profile::ssh::server::disable_agent_forwarding'),
    Boolean                      $challenge_response_auth  = lookup('profile::ssh::server::challenge_response_auth'),
    Optional[Integer]            $max_sessions             = lookup('profile::ssh::server::max_sessions'),
    Optional[String[1]]          $max_startups             = lookup('profile::ssh::server::max_startups'),
    Boolean                      $gateway_ports            = lookup('profile::ssh::server::gateway_ports'),
) {
    class {'ssh::server':
        * => wmflib::dump_params(),
    }
}
