# Puppet reporter to log events to logstash
#
# Based on https://github.com/logstash/puppet-logstash-reporter
#
# Copyright 2013 EvenUp Inc.
# Copyright © 2014 Bryan Davis and Wikimedia Foundation.
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
    rescue Exception => e
        raise(Puppet::ParseError, "Failed to load logstash report config file #{config_file}: #{e.message}")
    end

    SERVER_NAME = Socket.gethostbyname(Socket.gethostname).first

    def process
        # Convert Puppet::Transaction::Report object to a logstash event
        event = {
            '@timestamp'            => self.logs.last.time.utc.iso8601,
            '@version'              => 1,
            'host'                  => self.host,
            'client'                => self.host,
            'server'                => SERVER_NAME,
            'message'               => "Puppet run on #{self.host} - #{self.status}",
            'type'                  => 'puppet',
            'channel'               => self.kind,
            'environment'           => self.environment,
            'report_format'         => self.report_format,
            'transaction_uuid'      => self.transaction_uuid,
            'configuration_version' => self.configuration_version,
            'puppet_version'        => self.puppet_version,
            'status'                => self.status,
            'start_time'            => self.logs.first.time.utc.iso8601,
            'end_time'              => self.logs.last.time.utc.iso8601,
            'log_messages'          => self.logs.map(&:to_report),
            'metrics'               => {},
        }

        self.metrics.each do |category,v|
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
        rescue Exception => e
            Puppet.err("Failed to write to #{CONFIG[:host]} on port #{CONFIG[:port]}: #{e.message}")
        end
    end
end
