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
#   URL for favicon. (Optional)
#
# [*doctitle*]
#   HTML Document title. (Required)
#
#   Default: 'Wikimedia Error'
#
# [*pagetitle*]
#   Page heading. (Required)
#
#   Default: 'Error'
#
# [*content*]
#   Main HTML content, after logo and first heading. (Required)
#
#   Default: ''
#
# [*logo_link*]
#   URL for anchor link around logo. Set to undef to disable link. (Optional)
#
#   Default: 'https://www.wikimedia.org'
#
#   Default: 'Wikimedia Error'
#
# [*logo_src*]
#   URL for logo image. (Required)
#
#   Default: 'https://www.wikimedia.org/static/images/wmf.png'
#
# [*logo_srcset*]
#   HTML srcset attribute value for logo image. (Required)
#
#   Default: 'https://www.wikimedia.org/static/images/wmf-2x.png 2x'
#
# [*footer*]
#   Optional HTML content for the footer. (Optional)
#
define mediawiki::errorpage(
    $filepath = $name,
    $owner = 'root',
    $group = 'root',
    $mode = '0444',
    $favicon = undef,
    $doctitle = 'Wikimedia Error',
    $pagetitle = 'Error',
    $logo_link = 'https://www.wikimedia.org',
    $logo_src = 'https://www.wikimedia.org/static/images/wmf.png',
    $logo_srcset = 'https://www.wikimedia.org/static/images/wmf-2x.png 2x',
    $content = '',
    $footer = undef,
) {
    $errorpage = {
        favicon     => $favicon,
        title       => $doctitle,
        pagetitle   => $pagetitle,
        logo_link   => $logo_link,
        logo_src    => $logo_src,
        logo_srcset => $logo_srcset,
        content     => $content,
        footer      => $footer,
    }
    file { $filepath:
        owner  => $owner,
        group  => $group,
        mode   => $mode,
        source => template('mediawiki/errorpage.html.erb'),
    }
}
