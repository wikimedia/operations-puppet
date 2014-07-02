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
    unless File.exist?(config_file)
        raise(Puppet::ParseError, "Logstash report config file #{config_file} missing or not readable")
    end

    CONFIG = YAML.load_file(config_file)
    SERVER_NAME = Socket.gethostbyname(Socket.gethostname).first

    def process
        # Convert Puppet::Transaction::Report object to logstash events
        event = Hash.new
        event['@timestamp'] = self.logs.last.time.utc.iso8601
        event['@version'] = 1
        event['host'] = self.host
        event['client'] = self.host
        event['server'] = SERVER_NAME
        event['message'] = "Puppet run on #{self.host} - #{self.status}"
        event['type'] = 'puppet'
        event['channel'] = self.kind
        event['environment'] = self.environment
        event['report_format'] = self.report_format
        event['transaction_uuid'] = self.transaction_uuid
        event['configuration_version'] = self.configuration_version
        event['puppet_version'] = self.puppet_version
        event['status'] = self.status
        event['start_time'] = self.logs.first.time.utc.iso8601
        event['end_time'] = self.logs.last.time.utc.iso8601
        event['metrics'] = {}
        self.metrics.each do |k,v|
            event['metrics'][k] = {}
            v.values.each do |val|
                event['metrics'][k][val[1]] = val[2]
            end
        end
        event['log_messages'] = self.logs.map { |log| log.to_report }

        begin
            Timeout::timeout(CONFIG[:timeout]) do
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
