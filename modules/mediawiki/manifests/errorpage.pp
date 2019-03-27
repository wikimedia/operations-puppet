# == Define: mediawiki::errorpage
#
# Creates a file based on the error page template.
#
# === Usage
# mediawiki::errorpage { '/tmp/error-example.html':
#     content => '<p>Example</p>'
# }
#
# === Parameters
#
# [*filepath*]
#   The file path for File resource. (Required)
#
# [*favicon*]
#   URL for favicon. (Use undefined to disable)
#
#   Default: undef
#
# [*doctitle*]
#   HTML Document title.
#
#   Default: 'Wikimedia Error'
#
# [*pagetitle*]
#   Page heading.
#
#   Default: 'Error'
#
# [*content*]
#   Main HTML content, after logo and first heading. (Required)
#
#   Default: ''
#
# [*logo_link*]
#   URL for anchor link around logo. (Use undef to omit link.)
#
#   Default: 'https://www.wikimedia.org'
#
# [*logo_src*]
#   URL for logo image.
#
#   Default: 'https://www.wikimedia.org/static/images/wmf-logo.png'
#
# [*logo_srcset*]
#   HTML srcset attribute value for logo image.
#
#   Default: 'https://www.wikimedia.org/static/images/wmf-logo-2x.png 2x'
#
# [*logo_width*]
#   Width attribute for logo image.
#
#   Default: 135
#
# [*logo_height*]
#   Height attribute for logo image.
#
#   Default: 101
#
# [*logo_alt*]
#   Alternate text for logo image.
#
#   Default: 'Wikimedia'
#
# [*footer*]
#   Optional HTML content for the footer. (Use undefined to disable)
#
#   Default: undef
#
define mediawiki::errorpage(
    Stdlib::Unixpath $filepath = $name,
    String $owner = 'root',
    String $group = 'root',
    Stdlib::Filemode $mode = '0444',
    Optional[String] $favicon = undef,
    String $doctitle = 'Wikimedia Error',
    String $pagetitle = 'Error',
    Stdlib::Httpurl $logo_link = 'https://www.wikimedia.org',
    String $logo_src = 'https://www.wikimedia.org/static/images/wmf-logo.png',
    String $logo_srcset = 'https://www.wikimedia.org/static/images/wmf-logo-2x.png 2x',
    Integer $logo_width = 135,
    Integer $logo_height = 101,
    String $logo_alt = 'Wikimedia',
    Optional[String] $content = '',
    Optional[String] $footer = undef,
) {
    $errorpage = {
        favicon     => $favicon,
        title       => $doctitle,
        pagetitle   => $pagetitle,
        logo_link   => $logo_link,
        logo_src    => $logo_src,
        logo_srcset => $logo_srcset,
        logo_width  => $logo_width,
        logo_height => $logo_height,
        logo_alt    => $logo_alt,
        content     => $content,
        footer      => $footer,
    }
    file { $filepath:
        owner   => $owner,
        group   => $group,
        mode    => $mode,
        content => template('mediawiki/errorpage.html.erb'),
    }
}
