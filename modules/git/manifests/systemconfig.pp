# == git::systemconfig
#
# Generate /etc/gitconfig based on a hash of gitconfig values.
#
# Should be the same as executing git config --system. It is useful for use
# cases like the Analytics hosts whithin the related VLAN, that needs a common
# shared http[s].proxy configuration to be applied for each user.
#
# The file will be owned by root since it is fully managed by puppet.
#
# Parameters:
#  [*settings*]
#    Hash of gitconfig section name, each should be in turn a hash
#    of configuration name => value.
#  [*priority*]
#    Configuration loading priority. Default: '10'.
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
    Integer[1,99] $priority = 10,
) {
  include ::git::globalconfig

  $safe_title = $title.regsubst('\W', '_', 'G')
  $file_path = '/etc/gitconfig.d/%.2d-%s.gitconfig'.sprintf($priority, $safe_title)

  file { $file_path:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template( 'git/gitconfig.erb' ),
    notify  => Exec['update-gitconfig'],
  }
}
