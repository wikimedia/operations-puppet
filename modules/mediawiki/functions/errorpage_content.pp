# SPDX-License-Identifier: Apache-2.0

# Generate the html for a wmf-style error page
#
# NOTE: Keep options and defaults in sync with mediawiki::errorpage()
#
# NOTE: Refer to mediawiki::errorpage() for parameter documentation.
#
function mediawiki::errorpage_content(Optional[Mediawiki::Errorpage::Options] $options) >> String {
    $defaults = {
        'browsersec_comment' => false,
        'favicon'            => undef,
        'title'              => 'Wikimedia Error',
        'pagetitle'          => 'Error',
        'logo_link'          => 'https://www.wikimedia.org',
        'logo_src'           => 'https://www.wikimedia.org/static/images/footer/wikimedia.svg',
        'logo_width'         => 120,
        'logo_height'        => 120,
        'logo_alt'           => 'Wikimedia',
        'content'            => undef,
        'footer'             => undef,
        # https://wikitech.wikimedia.org/wiki/Wikitech:Cloud_Services_Terms_of_use#4.7_Use_of_Wikimedia_logos
        'wmf_branding'       => $::realm == 'production',
    }
    $errorpage = $defaults.stdlib::merge($options)
    template('mediawiki/errorpage.html.erb')
}
