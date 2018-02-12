# Role class for chromium_render
class role::chromium_render {
    system::role { 'role::chromium_render':
        description => 'A MediaWiki service for rendering wiki pages as PDFs using headless Chromium.',
    }

    include ::profile::chromium_render
}
