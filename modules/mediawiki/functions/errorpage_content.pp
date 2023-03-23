# SPDX-License-Identifier: Apache-2.0
# Generate the html for a wmf-style error page
function mediawiki::errorpage_content(Optional[Mediawiki::Errorpage::Options] $options) >> String {
    $defaults = {
        'title'              => 'Wikimedia Error',
        'pagetitle'          => 'Error',
        'logo_link'          => 'https://www.wikimedia.org',
        'logo_src'           => 'https://www.wikimedia.org/static/images/wmf-logo.png',
        'logo_srcset'        => 'https://www.wikimedia.org/static/images/wmf-logo-2x.png 2x',
        'logo_width'         => 135,
        'logo_height'        => 101,
        'logo_alt'           => 'Wikimedia',
        'browsersec_comment' => false,
    }
    $errorpage = $defaults.merge($options)
    template('mediawiki/errorpage.html.erb')
}
