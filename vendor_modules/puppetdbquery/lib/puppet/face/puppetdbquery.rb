require 'puppet/application/puppetdbquery'
require 'puppet/face'
require 'puppet/util/colors'

Puppet::Face.define(:puppetdbquery, '1.0.0') do
  require 'puppetdb/connection'
  PuppetDB::Connection.check_version

  extend Puppet::Util::Colors

  copyright 'Erik Dalen', 2012..2017
  license 'Apache 2 license; see COPYING'

  option '--host PUPPETDB' do
    summary 'Host running PuppetDB. '
    default_to { Puppet::Application::Puppetdbquery.setting[:host] }
  end

  option '--port PORT' do
    summary 'Port PuppetDB is running on'
    default_to { Puppet::Application::Puppetdbquery.setting[:port] }
  end

  option '--no_ssl' do
    summary 'Talk plain HTTP instead of HTTPS'
    default_to { !Puppet::Application::Puppetdbquery.setting[:use_ssl] }
  end

  action :facts do
    summary 'Serves as an interface to puppetdb allowing a user to query for a list of nodes'

    description <<-EOT
      Here is a ton of more useful information :)
    EOT

    arguments '<query>'

    option '--facts FACTS' do
      summary 'facts to return that represent each host'
      description <<-EOT
        Filter for the fact subcommand can be used to specify the facts to filter for.
        It accepts either a string or a comma delimited list of facts.
      EOT
      default_to { '' }
    end

    when_invoked do |query, options|
      puppetdb = PuppetDB::Connection.new options[:host], options[:port], !options[:no_ssl]
      parser = PuppetDB::Parser.new
      if options[:facts] != ''
        facts = options[:facts].split(',')
        factquery = parser.facts_query(query, facts)
      else
        facts = [:all]
        factquery = parser.parse(query, :facts)
      end
      parser.facts_hash(puppetdb.query(:facts, factquery, :extract => [:certname, :name, :value]), facts)
    end
  end

  action :nodes do
    summary 'Perform complex queries for nodes from PuppetDB'
    description <<-EOT
      Here is a ton of more useful information :)
    EOT

    arguments '<query>'

    option '--node_info' do
      summary 'return full info about each node or just name'
      description <<-EOT
        If true the full information about each host is returned including fact, report and catalog timestamps.
      EOT
      default_to { false }
    end

    when_invoked do |query, options|
      puppetdb = PuppetDB::Connection.new options[:host], options[:port], !options[:no_ssl]
      parser = PuppetDB::Parser.new
      query = parser.parse(query, :nodes)

      if options[:node_info]
        nodes = puppetdb.query(:nodes, query)
        Hash[nodes.collect { |node| [node['certname'], node.reject { |k, _v| k == 'certname' }] }]
      else
        nodes = puppetdb.query(:nodes, query, :extract => :certname)
        nodes.collect { |node| node['certname'] }
      end
    end
  end

  action :events do
    summary 'Serves as an interface to puppetdb allowing a user to query for a list of events'

    description <<-EOT
      Get all avents for nodes matching the query specified.
    EOT

    arguments '<query>'

    option '--since SINCE' do
      summary 'Get events since this time'
      description <<-EOT
        Uses chronic to parse time, can be specified in many human readable formats.
      EOT
      default_to { '1 hour ago' }
    end

    option '--until UNTIL' do
      summary 'Get events until this time'
      description <<-EOT
        Uses chronic to parse time, can be specified in many human readable formats.
      EOT
      default_to { 'now' }
    end

    option '--status STATUS' do
      summary 'Only get events with specified status, skipped, success or failure'
      description <<-EOT
        Only get events of specified status, can be either all, skipped, success or failure.
      EOT
      default_to { 'all' }
    end

    when_invoked do |query, options|
      begin
        require 'chronic'
      rescue LoadError
        Puppet.err "Failed to load 'chronic' dependency. Install using `gem install chronic`"
        raise
      end

      puppetdb = PuppetDB::Connection.new options[:host], options[:port], !options[:no_ssl]
      parser = PuppetDB::Parser.new
      nodes = puppetdb.query(:nodes, parser.parse(query, :nodes)).collect { |n| n['certname'] }
      starttime = Chronic.parse(options[:since], :context => :past, :guess => false).first.getutc.strftime('%FT%T.000Z')
      endtime = Chronic.parse(options[:until], :context => :past, :guess => false).last.getutc.strftime('%FT%T.000Z')

      events = []
      # Event API doesn't support subqueries at the moment and
      # we can't do too big queries, so fetch events for some nodes at a time
      nodes.each_slice(20) do |nodeslice|
        eventquery = ['and', ['>', 'timestamp', starttime], ['<', 'timestamp', endtime], ['or', *nodeslice.collect { |n| ['=', 'certname', n] }]]
        eventquery << ['=', 'status', options[:status]] if options[:status] != 'all'
        events.concat puppetdb.query(:events, eventquery)
      end

      events.sort_by do |e|
        "#{e['timestamp']}+#{e['resource_type']}+#{e['resource_title']}+#{e['property']}"
      end.each do |e|
        out = "#{e['certname']}: #{e['timestamp']}: #{e['resource_type']}[#{e['resource_title']}]"
        out += "/#{e['property']}" if e['property']
        out += " (#{e['old_value']} -> #{e['new_value']})" if e['old_value'] && e['new_value']
        out += ": #{e['message']}" if e['message']
        out.chomp!
        case e['status']
        when 'failure'
          puts colorize(:hred, out)
        when 'success'
          puts colorize(:green, out)
        when 'skipped'
          puts colorize(:hyellow, out) unless e['resource_type'] == 'Schedule'
        when 'noop'
          puts out
        end
      end
      nil
    end
  end
end
