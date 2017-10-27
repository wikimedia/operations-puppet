# == Class role::ci::publisher
#
# Intermediary rsync host in labs to let Jenkins slave publish their results
# safely.  The production machine hosting doc.wikimedia.org can then fetch the
# doc from there.
#
# filtertags: labs-project-integration
class role::ci::publisher {
    system::role { 'role::ci::publisher':
        description => 'rsync host to publish Jenkins artifacts',
    }

    include profile::ci::publisher
}

