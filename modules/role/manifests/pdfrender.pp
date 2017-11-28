class role::pdfrender {
    system::role { 'pdfrender':
        description => 'A PDF render service based on Electron',
    }

    include ::profile::pdfrender
}
