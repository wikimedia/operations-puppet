class role::pdfrender {

    system::role { 'role::pdfrender':
        description => 'A PDF render service based on Electron',
    }

    include ::pdfrender

}

