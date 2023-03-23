# SPDX-License-Identifier: Apache-2.0
# Options for the error page function
# All entries are optional, as defaults are provided in
# mediawiki::errorpage_content.
type Mediawiki::Errorpage::Options = Struct[{
    'title'              => Optional[String],
    'favicon'            => Optional[String],
    'pagetitle'          => Optional[String],
    'logo_link'          => Optional[Stdlib::Httpurl],
    'logo_src'           => Optional[String],
    'logo_srcset'        => Optional[String],
    'logo_width'         => Optional[Integer],
    'logo_height'        => Optional[Integer],
    'logo_alt'           => Optional[String],
    'browsersec_comment' => Optional[Boolean],
    'content'            => Optional[String],
    'footer'             => Optional[String],
    'margin'             => Optional[String],
    'margin_top'         => Optional[String],
}]
