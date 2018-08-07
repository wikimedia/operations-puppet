# Define that sets up a virtualhost for a mediawiki
# wiki, according to the needs of the apache configuration
# used by the wikimedia foundation.
#
# === Parameters
#
# [*docroot*] The DocumentRoot of the virtualhost
#
# [*ensure*] The usual ensure parameter.
#
# [*server_name*] The ServerName of the vhost. Defaults to the resource title
#
# [*server_aliases*] Array of server aliases, or undef. Defaults to undef
#
# [*legacy_rewrites*] Wether or not legacy rewrites should be added
#
# [*public_rewrites*] Rewrites for favicon, robots.txt necessary for public wikis
#
# [*short_urls*] Whether or not support for short urls should be added
#
# [*https_only*] Wether or not to force https everywhere.
#
# [*encoded_slashes*] AllowEncodedSlashes apache httpd directive.
#
# [*$additional_rewrites*] A struct of early and late rewriterules to add before or after
#                          the main rewrites.
#
# [*$variant_aliases*] A list of language variant aliases for the current vhost.
#
# [*declare_site*] Wether to declare the site as enabled in the configuration of httpd or not.
#
# [*domain_suffix*] Suffix to use in redirects et al (prod/beta/staging use)
#
define mediawiki::web::vhost(
    String $docroot,
    Wmflib::Ensure $ensure = present,
    String $server_name = $title,
    Optional[Array[String]] $server_aliases = undef,
    Boolean $public_rewrites = true,
    Boolean $legacy_rewrites = true,
    Boolean $short_urls = false,
    Boolean $https_only = false,
    Enum['On', 'Off', 'NoDecode'] $encoded_slashes = 'On',
    Mediawiki::Rewrites $additional_rewrites = {'early' => [], 'late' => []},
    Array $variant_aliases = [],
    Integer[0, 99] $priority = 50,
    Boolean $declare_site = false,
    String $domain_suffix = 'org',
) {
    $content = template('mediawiki/apache/mediawiki-vhost.conf.erb')

    if $declare_site {
        httpd::site { $title:
            ensure   => $ensure,
            priority => $priority,
            content  => $content,
        }
    } else {
        # If we're not declaring a separate vhost
        file { "/etc/apache2/sites-available/${title}.conf":
            ensure  => $ensure,
            content => $content,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            require => Package['apache2'],
            notify  => Service['apache2'],
        }
    }
}
