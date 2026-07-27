# SPDX-License-Identifier: Apache-2.0
# @summary converge live Kafka topic configuration to Puppet-declared state
#
# Renders the desired topic configuration from hieradata and runs
# kafka-configurator against the local cluster to converge it.
#
# The tool is a reconcile-and-exit CLI, not a daemon. Divergence has two
# sources -- the declared state changed (hieradata), or the live cluster
# was mutated out-of-band -- and each gets its own trigger into the same
# systemd oneshot unit:
#
#   * Puppet notifies the unit whenever the rendered desired state
#     changes, so a merged hieradata change converges within one agent
#     run rather than waiting for the next tick
#   * A timer runs it on a schedule, bounding the lifetime of drift
#     Puppet cannot see: a hand-run `kafka configs --alter` changes the
#     cluster without changing any file on any host
#
# @param runner_host
#   The single host allowed to converge this cluster. Every other host
#   ensures the runner artifacts are absent, so only one broker
#   converges the cluster, apart from the old and new runner
#   overlapping until the old host's next Puppet run. Moving
#   runner_host (or unsetting it) tears down the old runner rather
#   than leaving its timer converging a frozen desired state. The
#   broker roles include this class on every broker, so the default
#   is unset: nobody runs.
# @param topics
#   Desired per-topic configuration overrides, as
#   {topic => {config => {key => value}}}. Topics absent from the
#   cluster are skipped; overrides not listed here are left alone.
# @param features
#   Feature settings passed to kafka-configurator.
# @param dry_run
#   True (the default) passes --dry-run, so runs report the pending diff
#   without writing; a cluster stays in this mode until its dry-run
#   output has shown no unexpected changes for long enough to trust it.
#   Set false to let the tool apply the diff.
# @param interval
#   systemd OnCalendar expression for how often to reconcile actual
#   state with desired state.
# @param bootstrap
#   librdkafka bootstrap.servers value, so host:port (or a comma
#   separated list of them) rather than a bare hostname.
#   Defaults to this host's own listener, TLS when the broker has
#   ssl_enabled and plaintext otherwise; metadata discovery finds the
#   rest of the cluster from there. Not localhost, whose name would
#   not match the broker certificate.
# @param tool
#   Path to the kafka-configurator executable, as installed by the
#   kafka-configurator package.
class profile::kafka::configurator (
    Optional[Stdlib::Fqdn]         $runner_host   = lookup('profile::kafka::configurator::runner_host', {'default_value' => undef}),
    Hash[String, Hash]             $topics        = lookup('profile::kafka::configurator::topics', {'default_value' => {}}),
    Hash[String, Hash[String, Boolean]] $features = lookup('profile::kafka::configurator::features'),
    Boolean                        $dry_run       = lookup('profile::kafka::configurator::dry_run', {'default_value' => true}),
    Systemd::Timer::Datetime       $interval      = lookup('profile::kafka::configurator::interval', {'default_value' => '*-*-* *:00/30:00'}),
    Optional[String[1]]            $bootstrap     = lookup('profile::kafka::configurator::bootstrap', {'default_value' => undef}),
    Stdlib::Absolutepath           $tool          = lookup('profile::kafka::configurator::tool', {'default_value' => '/usr/bin/kafka-configurator'}),
) {
    # We need the broker profile evaluated first because we depend on
    # its listener and cert variables below
    require profile::kafka::broker

    $config_dir  = '/etc/kafka-configurator'
    $config_file = "${config_dir}/config.yaml"

    # Client identity: the broker's own PKI certificate, whose CN is
    # already in the cluster's super.users, so no ACL has to exist
    # before the tool can read anything. When it's time to run this
    # in production rather than the cloud test bed, provision a
    # dedicated PKI client certificate (T276088). broker.pp only
    # obtains a certificate when ssl_enabled, so a plaintext-only
    # broker gets a plaintext-only client.
    #
    # librdkafka will not present a bare leaf (it silently connects
    # with no client identity), so this is the chained file
    if $profile::kafka::broker::ssl_enabled {
        $ssl_cert = $profile::kafka::broker::ssl_cert
        $cluster  = {
            'bootstrap' => pick($bootstrap, "${facts['networking']['fqdn']}:${profile::kafka::broker::ssl_port}"),
            'ssl'       => {
                'ca'          => '/etc/ssl/certs/wmf-ca-certificates.crt',
                'certificate' => $ssl_cert['chained'],
                'key'         => $ssl_cert['key'],
            },
        }
    } else {
        $cluster = {
            'bootstrap' => pick($bootstrap, "${facts['networking']['fqdn']}:${profile::kafka::broker::plaintext_port}"),
        }
    }

    if $runner_host == $facts['networking']['fqdn'] {

        $config = {
            'cluster'  => $cluster,
            'features' => $features,
            'topics'   => $topics,
        }

        file { $config_dir:
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
        }

        file { $config_file:
            ensure  => file,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => to_yaml($config),
            require => File[$config_dir],
            # If the desired state declared in hiera changed, run the
            # reconciliation as part of the puppet run
            notify  => Exec['kafka-configurator reconcile'],
        }

        $dry_run_flag = $dry_run.bool2str(' --dry-run', '')

        # The broker's private key is 0440 and owned by the kafka user,
        # so kafka is the least privilege that can read it
        systemd::timer::job { 'kafka-configurator':
            ensure          => present,
            description     => 'Converge Kafka topic configuration to Puppet-declared state',
            command         => "${tool} --config ${config_file}${dry_run_flag}",
            user            => 'kafka',
            interval        => {'start' => 'OnCalendar', 'interval' => $interval},
            logging_enabled => true,
            require         => File[$config_file],
            # dry_run and the tool path live in the unit's command line,
            # not in config.yaml, so a change to them rewrites only the
            # unit. Run the reconciliation now rather than leaving the
            # new command unused until the next tick
            notify          => Exec['kafka-configurator reconcile'],
        }

        exec { 'kafka-configurator reconcile':
            command     => '/bin/systemctl start kafka-configurator.service',
            refreshonly => true,
            require     => Systemd::Timer::Job['kafka-configurator'],
        }
    } else {
        # A moved runner_host or a disabled cluster must tear down the
        # old runner: an orphaned timer would keep converging the
        # cluster with a frozen desired state
        systemd::timer::job { 'kafka-configurator':
            ensure      => absent,
            description => 'Converge Kafka topic configuration to Puppet-declared state',
            command     => "${tool} --config ${config_file}",
            user        => 'kafka',
            interval    => {'start' => 'OnCalendar', 'interval' => $interval},
        }

        file { $config_dir:
            ensure  => absent,
            recurse => true,
            force   => true,
        }
    }
}
