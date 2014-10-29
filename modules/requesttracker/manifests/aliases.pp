class requesttracker::aliases {

    mailalias { 'ops-request':
        recipient => 'ops-requests@rt.wikimedia.org',
    }

    mailalias { 'phabricator':
        recipient => 'rt@phabricator.wikimedia.org',
    }

}
