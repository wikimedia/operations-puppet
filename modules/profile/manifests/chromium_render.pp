# == Class: profile::chromium_render
# A MediaWiki service for rendering wiki pages as PDFs using headless Chromium.
class profile::chromium_render {
    service::node { 'chromium_render':
        healthcheck_url => '',
        has_spec        => true,
        deployment      => 'scap3',
    }
}
