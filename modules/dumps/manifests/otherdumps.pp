class dumps::otherdumps {
    # fixme only vars needed should get passed
    # fixme put requires in where needed

    class {'::dumps::otherdumps::config':
        user => $user,
        confsdir => $confsdir,
        repodir => $repodir,
        otherdumpsdir => $otherdumpsdir,
        apachedir => $apachedir,
        dumpdatadir => $dumpdatadir,
    }
    class {'::dumps::otherdumps::daily':
        user => $user,
        confsdir => $confsdir,
        repodir => $repodir,
        otherdumpsdir => $otherdumpsdir,
        apachedir => $apachedir,
        dumpdatadir => $dumpdatadir,
    }
    class {'::dumpscrons::otherdumps::weekly':
        user => $user,
        confsdir => $confsdir,
        repodir => $repodir,
        otherdumpsdir => $otherdumpsdir,
        apachedir => $apachedir,
        dumpdatadir => $dumpdatadir,
    }
    class {'::dumps::otherdumps::wikidata':
        user => $user,
        confsdir => $confsdir,
        repodir => $repodir,
        otherdumpsdir => $otherdumpsdir,
        apachedir => $apachedir,
        dumpdatadir => $dumpdatadir,
    }
}
