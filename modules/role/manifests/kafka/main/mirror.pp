# == Class role::kafka::main::mirror
#
# Defines Kafka MirrorMaker instances to Mirror
# datacenter prefixed topics from a number of source
# clusters to a single destination cluster.
#
# The hiera defaults used by this role are suitable for mirroring 'main'
# production Kafka clusters into each other. E.g.  Including this in codfw will
# mirror 'eqiad*' topics from main-eqiad into main-codfw, and including
# this in eqiad will mirror 'codfw*' topics from main-codfw into main-eqiad.
#
# These defaults are 100% overridable for testing in labs.  If you are
# applying this class in labs, you must override both of the
# kafka_mirror_source_clusters and kafka_mirror_destination_cluster
# Hiera parameters to match your Kafka cluster configs there.
#
# == Hiera Parameters
#
# [*kafka_mirror_source_clusters*]
#   A hash of the form
#   { site => [prefix1, prefix2, ...], site2 => [prefix1], ... }
#   This will be given to the kafka_mirror_resources function.
#   The default is to pick this site's opposing main cluster.
#
# [*kafka_mirror_destination_cluster*]
#   Either a string prefix cluster name, or a two element array of [prefix,
#   site].  This will be given to the kafka_mirror_resouces function.
#   Default: ['main', $::site]
#
# [*kafka_mirror_defaults*]
#   Hash of defaults that will be given to all MirrorMaker instances
#   instantiated by this class.  Default {}.  This class
#   already specifies several defaults to give that are appropriate
#   for mirroring main clusters into each other.  Most importantly:
#     'whitelist' => "^${source_site}[\._].+"
#   If you need to override any defaults via hiera, set them here.
#
# The MirrorMaker instances should run on the destination
# hosts.  That is, the instances that produce
# to main-eqiad and consume from main-codfw run
# on the main-eqiad brokers, and vice versa, as it is
# wiser to colocate the instance with the destination cluster.
#
# It is safe to include this class on multiple hosts.
# Each host it is included on will just fire up a new MirrorMaker
# consumer that will be auto balanced by Kafka.
#
class role::kafka::main::mirror {
    # If we are in eqiad, then the default source cluster will be main-codfw.
    # If we are in codfw, then the default source cluster will be main-eqiad
    $source_site = $::site ? {
        'eqiad' => 'codfw',
        'codfw' => 'eqiad',
    }
    $source_clusters = hiera(
        'kafka_mirror_source_clusters',
        { $source_site => ['main'] }
    )

    # Only mirror topics from the source clusters that are prefixed with
    # with source cluster name.  This will be a regex like
    #   '^(sourceA|sourceB)[\._].+'
    $source_topic_whitelist = inline_template('^(<%= @source_clusters.keys.sort.join("|")%>)[\._].+')

    # The default destination cluster will be the current site's main cluster.
    $destination_cluster = hiera(
        'kafka_mirror_destination_cluster',
        ['main', $::site]
    )

    # Defaults for main mirror instances.  These will be overridden
    # by hiera kafka_mirror_defaults.
    $main_mirror_defaults = {
        # Only mirror topics from the source that are prefixed with
        # $source_site[\._].
        'whitelist'                 => $source_topic_whitelist,
        'num_streams'               => 2,
        'offset_commit_interval_ms' => 5000,
    }
    # Merge any hiera configured mirror::instance defaults
    # over the ones that we should use for main cluster mirrors.
    $mirror_defaults = merge(
        $main_mirror_defaults,
        hiera('kafka_mirror_defaults', {})
    )

    # Do not allow override of whitelist.
    # For main to main cluster mirroring, it is very important
    # that we don't set up an infinite mirror.  E.g. we
    # do not want to mirror eqiad prefixed topics from main-eqiad to
    # main-codfw and then back to main-eqiad again.
    if $mirror_defaults['whitelist'] != $source_topic_whitelist {
        fail('Cannot override topic whitelist in role::kafka::main::mirror.  This avoids accidentally creating an infinite mirror')
    }

    # Instantiate the mirrors.
    class { '::confluent::kafka::mirrors':
        mirrors         => kafka_mirror_resources(
            $source_clusters,
            $destination_cluster,
        ),
        mirror_defaults => $mirror_defaults,
    }
}
