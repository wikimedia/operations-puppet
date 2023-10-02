# Puppet reporter to log events to logstash
#
# Based on https://github.com/logstash/puppet-logstash-reporter
#
# Copyright 2013 EvenUp Inc.
# Copyright 2014 Bryan Davis and Wikimedia Foundation.
# License http://www.apache.org/licenses/LICENSE-2.0

require 'puppet'
require 'socket'
require 'timeout'
require 'json'
require 'yaml'
require 'time'
require 'syslog'

Puppet::Reports.register_report(:logstash) do
  desc 'Send logs to a logstash instance'

  SERVER_NAME = Socket.gethostbyname(Socket.gethostname).first

  def process
    # Convert Puppet::Transaction::Report object to a logstash event
    case status
    when 'failed'
      event_outcome = 'failure'
      event_type = 'error'
    when 'changed'
      event_outcome = 'success'
      event_type = 'change'
    when 'unchanged'
      event_outcome = 'success'
      event_type = 'info'
    end

    # during testing server_used wasn't avalible
    server_name = local_variables.include?(:server_used) ? server_used : SERVER_NAME

    event = {
      '@timestamp' => logs.last.time.utc.iso8601,
      'message'    => "Puppet run on #{host} - #{status}",
      'type'       => 'puppet',
      'package'    => {
        'name'    => 'puppet',
        'version' =>  puppet_version
      },
      'ecs' => {
        'version' => '1.7.0'
      },
      'host' => {
        'name'     => host,
        'hostname' => host.split('.')[0],
        'domain'   => host.split('.', 2)[1],
      },
      'server' => {
        'address' => server_name,
        # from the docs it seems server.domain here should be the fqdn
        # but when used above for host it is the hosts domain???
        'domain'  => server_name,
      },
      'git' => {
        'repo' => {
          'name' => 'operations/puppet',
        }
      },
      'event' => {
        'id'       => transaction_uuid,
        'category' => 'configuration',
        'type'     => event_type,
        'kind'     => 'metric',
        'provider' => 'puppet',
        'created'  => Time.now.utc.iso8601,
        'start'    => time.utc.iso8601,
        'duration' => metrics['time']['total'],
        'end'      => logs.last.time.utc.iso8601,
        'outcome'  => event_outcome,
        'reason'   => configuration_version,
      },
      'metrics' => {
        'puppet' => {'changes' => {}, 'runtime' => {}, 'resources' => {}}
      },
    }

    # configuration_version looks like:
    # ($git_sha) $author - $message
    result = /\((?<sha1>\h+)\)\s+(?<author>\S+)/.match(configuration_version.to_s)
    if result
      event['git']['commit'] = {
        'author' => result['author'],
        'hash' => { 'sha1' => { 'short' => result['sha1'] }}
      }
    end

    event['metrics']['puppet']['changes']['total'] = metrics['changes'].values[0][2]
    metrics['time'].values.each do |name, _, value|
      event['metrics']['puppet']['runtime'][name] = {'seconds' => value}
    end

    metrics['resources'].values.each do |name, _, value|
      if name == 'total'
        event['metrics']['puppet']['resources'][name] = value
      else
        event['metrics']['puppet']['resources'][name] = {'total' => value}
      end
    end
    Syslog.open("puppetserver-reporter", Syslog::LOG_PID, Syslog::LOG_INFO) unless Syslog.opened?
    Syslog.log(Syslog::LOG_INFO, "@cee: #{event.to_json}")
  end
end
