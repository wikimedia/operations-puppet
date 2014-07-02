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

    def process
        # Convert Puppet::Transaction::Report object to logstash events
        events = []
        self.logs.each do |log|
            events << format_log(self.host, log)
        end

        event = Hash.new
        event['@timestamp'] = self.logs.last.time.utc.iso8601
        event['@version'] = 1
        event['host'] = self.host
        event['message'] = "Puppet run on #{self.host} #{self.status}"
        event['type'] = 'puppet'
        event['channel'] = self.kind
        event['environment'] = self.environment
        event['report_format'] = self.report_format
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
        events << event

        begin
            Timeout::timeout(CONFIG[:timeout]) do
                sock = TCPSocket.new "#{CONFIG[:host]}" , CONFIG[:port]
                events.each do |event|
                    sock.puts event.to_json
                end
                sock.flush
                sock.close
            end
        rescue Exception => e
            Puppet.err("Failed to write to #{CONFIG[:host]} on port #{CONFIG[:port]}: #{e.message}")
        end
    end

    # Convert a Puppet::Util::Log object into a logstash event
    def format_log(host, log)
        event = Hash.new
        event['@timestamp'] = log.time.utc.iso8601
        event['@version'] = 1
        event['host'] = host
        event['message'] = log.message
        event['type'] = 'puppet'
        event['channel'] = log.source
        event['file'] = log.file
        event['line'] = log.line
        event['level'] = "#{log.level}"
        event['puppet_tags'] = []
        log.tags.each do |tag|
            event['tags'] << tag
        end
        return event
    end
end
