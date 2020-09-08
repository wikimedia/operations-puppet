# == git::systemconfig
#
# Generate /etc/gitconfig based on a hash of gitconfig values.
# Should be the same as executing git config --system. It is useful for use
# cases like the Analytics hosts whithin the related VLAN, that needs a common
# shared http[s].proxy configuration to be applied for each user.
#
# Parameters:
#  [*settings*]
#    Hash of gitconfig section name, each should be in turn a hash
#    of configuration name => value.
#
# Example usage:
#
# git::systemconfig { 'setup_http_proxy':
#    settings => {
#        # https://wikitech.wikimedia.org/wiki/HTTP_proxy
#        'http'  => {
#            'proxy' => "http://webproxy.${::site}.wmnet:8080"
#        },
#        'https' => {
#            'proxy' => "http://webproxy.${::site}.wmnet:8080"
#        },
#     },
# }
#
define git::systemconfig(
    Hash[String, Hash[String, String]] $settings,
) {
  require ::git::globalconfig

  file { "/etc/gitconfig.d/${title}.gitconfig":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template( 'git/gitconfig.erb' ),
  }
}
