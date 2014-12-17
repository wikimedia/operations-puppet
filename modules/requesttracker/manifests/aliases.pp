class requesttracker::aliases {

    mailalias { 'ops-request':
        recipient => 'ops-private@lists.wikimedia.org',
    }

    mailalias { 'codfw':
        recipient => 'ops-private@lists.wikimedia.org',
    }

    mailalias { 'core-ops':
        recipient => 'ops-private@lists.wikimedia.org',
    }

    mailalias { 'eqiad':
        recipient => 'ops-private@lists.wikimedia.org',
    }

    mailalias { 'esams':
        recipient => 'ops-private@lists.wikimedia.org',
    }

    mailalias { 'network':
        recipient => 'ops-private@lists.wikimedia.org',
    }

    mailalias { 'pmtpa':
        recipient => 'ops-private@lists.wikimedia.org',
    }

    mailalias { 'todo':
        recipient => 'ops-private@lists.wikimedia.org',
    }

    mailalias { 'ulsfo':
        recipient => 'ops-private@lists.wikimedia.org',
    }
        
    mailalias { 'phabricator':
        recipient => 'rt@phabricator.wikimedia.org',
    }
}
