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

Puppet::Reports.register_report(:logstash) do
    desc 'Send logs to a logstash instance'

    config_file = File.join([File.dirname(Puppet.settings[:config]), 'logstash.yaml'])
    begin
        CONFIG = YAML.load_file(config_file)
    # rubocop:disable Lint/RescueException
    rescue Exception => e
        raise(Puppet::ParseError, "Failed to load logstash report config file #{config_file}: #{e.message}")
    end
    # rubocop:enable Lint/RescueException

    SERVER_NAME = Socket.gethostbyname(Socket.gethostname).first

    def process
        # Convert Puppet::Transaction::Report object to a logstash event
        event = {
            '@timestamp'            => logs.last.time.utc.iso8601,
            '@version'              => 1,
            'host'                  => host,
            'client'                => host,
            'server'                => SERVER_NAME,
            'message'               => "Puppet run on #{host} - #{status}",
            'type'                  => 'puppet',
            'channel'               => kind,
            'environment'           => environment,
            'report_format'         => report_format,
            'transaction_uuid'      => transaction_uuid,
            'configuration_version' => configuration_version,
            'puppet_version'        => puppet_version,
            'status'                => status,
            'start_time'            => logs.first.time.utc.iso8601,
            'end_time'              => logs.last.time.utc.iso8601,
            'log_messages'          => logs.map(&:to_report),
            'metrics'               => {},
        }

        metrics.each do |category, v|
            event['metrics'][category] = {}
            v.values.each do |metric|
                # Each element is of the form [name, titleized_name, value]
                event['metrics'][category][metric[0]] = metric[2]
            end
        end

        begin
            Timeout.timeout(CONFIG[:timeout]) do
                sock = TCPSocket.new "#{CONFIG[:host]}" , CONFIG[:port]
                sock.puts event.to_json
                sock.flush
                sock.close
            end
        # rubocop:disable Lint/RescueException
        rescue Exception => e
            Puppet.err("Failed to write to #{CONFIG[:host]} on port #{CONFIG[:port]}: #{e.message}")
        end
        # rubocop:enable Lint/RescueException
    end
end
