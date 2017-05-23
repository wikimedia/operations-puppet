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
# [*doctitle*]
#   HTML Document title. (Required)
#
#   Default: 'Wikimedia Error'
#
# [*content*]
#   Main HTML content, after logo and first heading. (Required)
#
#   Default: ''
#
# [*footer*]
#   Optional HTML content for the footer. (Optional)
#
define mediawiki::errorpage(
    $filepath = $name,
    $doctitle = 'Wikimedia Error',
    $content = '',
    $footer = undef,
) {
    $errorpage  = {
        title   => $doctitle,
        content => $content,
        footer  => $footer,
    }
    file { $filepath:
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => template('mediawiki/errorpage.html.erb'),
    }
}
