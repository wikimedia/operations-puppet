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
function mediawiki::errorpage(Hash $params) {
    $errorpage = merge({
        title   => 'Wikimedia Error',
        content => '',
        footer  => undef,
    }, $params)
    inline_template('mediawiki/errorpage.html.erb')
}
