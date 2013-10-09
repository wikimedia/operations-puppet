# Puppet StatsD reporter
# Sends timing measurements for Puppet runs to StatsD
require 'puppet'
require 'yaml'
require 'erb'

Puppet::Reports.register_report(:statsd) do
    desc = 'Send Puppet metrics to StatsD'

    config_file = File.join Puppet.settings[:confdir], 'statsd.yaml'

    unless File.exist? config_file
        raise Puppet::ParseError, "Required StatsD reporter configuration file #{config_file} is missing"
    end

    config = YAML.load_file(config_file)

    STATSD_HOST = config[:statsd_host]
    STATSD_PORT = config[:statsd_port]
    METRIC_FORMAT = config[:metric_format]

    def process
        Puppet.notice "Sending metrics for #{self.host} to #{STATSD_HOST}:#{STATSD_PORT}."
        hostname = self.host
        socket = UDPSocket.new
        self.metrics['time'].values.each do |metric,description,value|
            value = (value * 1000).round  # Convert fractional seconds to whole miliseconds
            name = ERB.new(METRIC_FORMAT).result(binding)
            socket.send("#{name}:#{value}|ms", 0, STATSD_HOST, STATSD_PORT)
        end
        socket.close
    end
end
