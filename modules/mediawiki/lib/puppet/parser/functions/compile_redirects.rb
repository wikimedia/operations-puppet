# == Function: compile_redirects
#
# This is a Ruby compiler for a mini-language for URL rewriting schemes.
# The output it generates is an Apache config file. The syntax was invented by
# Tim Starling to eliminate common sources of errors.
#
# === Examples
#
# With puppet:// URL:
#
#   file { '/etc/apache2/conf.d/redirects.conf':
#     ensure  => present,
#     content => compile_redirects('puppet:///files/apache/redirects.dat'),
#   }
#
# With absolute file path:
#
#   file { '/etc/apache2/conf.d/redirects.conf':
#     ensure  => present,
#     content => compile_redirects('/etc/apache2/conf.d/redirects.dat'),
#   }
#
# With source as string:
#
#   file { '/etc/apache2/conf.d/redirects.conf':
#     ensure  => present,
#     content => compile_redirects(template('mediawiki/rewrites.erb')),
#   }
#
require 'stringio'

module DomainRedirects
  class Parser
    attr_accessor :line_num

    def initialize(source, web_server = 'apache')
      @lines = source.lines.map(&:rstrip)
      @web_server = web_server
      if @web_server == 'apache'
        @original_request = '$0'
        @group_dest = '%1'
      else
        @original_request = '$request_uri'
        @group_dest = '$1'
      end
      @rules = {
        :wildcard           => [],
        :plain              => [],
        :wildcard_override  => [],
        :plain_override     => [],
      }
    end

    def parse
      StringIO.open do |buf|
        parse_to(buf)
        buf.rewind
        buf.read
      end
    end

    def parse_to(dest)
      @lines.each_with_index do |line, i|
        @line_num = i + 1
        args = line.gsub(/#.*/, '').strip.split
        send(*args) unless args.empty?
      end
      check_orphan_overrides
      check_loops
      if @web_server == 'apache'
        write_apache_conf(dest)
      else
        write_nginx_conf(dest)
      end
    end

    def error(msg, line_num = @line_num)
      raise DomainRedirects::ParserError.new(msg, line_num)
    end

    # Process a funnel command at the current input position
    def funnel(domain, dest)
      dest_info = interpret_dest(dest)
      if domain.include? '*'
        wildcard_list = interpret_wildcard(domain)
        wildcard_list.each do |wildcard|
          domain_regex = wildcard[:domain_regex]
          if domain_regex.include? '('
            wildcard_dest = dest_info[:dest].gsub('*', @group_dest)
          else
            wildcard_dest = dest_info[:dest]
          end

          @rules[:wildcard] << {
            :domain       => domain,
            :domain_regex => domain_regex,
            :alias        => wildcard[:alias],
            :path_regex   => '.',
            :dest         => wildcard_dest,
            :dest_domain  => dest_info[:domain],
            :line_num     => @line_num,
          }
        end
      else
        @rules[:plain] << {
          :domain       => domain,
          :domain_regex => "=#{domain}",
          :alias        => domain,
          :path_regex   => '.',
          :dest         => dest_info[:dest],
          :dest_domain  => dest_info[:domain],
          :line_num     => @line_num,
        }
      end
    end

    # Process a rewrite command at the current input position
    def rewrite(domain, dest)
      dest_info = interpret_dest(dest)
      dest_info[:dest].sub!(%r{/$}, '')
      if domain.include? '*'
        wildcard_list = interpret_wildcard(domain)
        wildcard_list.each do |wildcard|
          domain_regex = wildcard[:domain_regex]
          wildcard_dest = dest_info[:dest]
          wildcard_dest.gsub!('*', @group_dest) if domain_regex.include? '('
          @rules[:wildcard] << {
            :domain       => domain,
            :domain_regex => domain_regex,
            :alias        => wildcard[:alias],
            :path_regex   => '^[^\x00-\x1F]*',
            :dest         => "#{wildcard_dest}#{@original_request}",
            :dest_domain  => dest_info[:domain],
            :line_num     => @line_num,
          }
        end
      else
        @rules[:plain] << {
          :domain       => domain,
          :domain_regex => "=#{domain}",
          :alias        => domain,
          :path_regex   => '^[^\x00-\x1F]*',
          :dest         => dest_info[:dest] + @original_request,
          :dest_domain  => dest_info[:domain],
          :line_num     => @line_num,
        }
      end
    end

    # Process an override command at the current input position
    def override(source, dest)
      dest_info = interpret_dest(dest)
      domain, path = source.split('/', 2)
      error('the source of an override must include a path component') if path.nil?
      if domain.include? '*'
        wildcard_list = interpret_wildcard(domain)
        wildcard_list.each do |wildcard|
          domain_regex = wildcard[:domain_regex]
          if domain_regex.include? '('
            wildcard_dest = dest_info[:dest].gsub('*', @group_dest)
          else
            wildcard_dest = dest_info[:dest]
          end
          @rules[:wildcard_override] << {
            :domain       => domain,
            :domain_regex => domain_regex,
            :alias        => wildcard[:alias],
            :path         => Regexp.quote(path),
            :path_regex   => '^/' + Regexp.quote(path) + '$',
            :dest         => wildcard_dest,
            :dest_domain  => dest_info[:domain],
            :line_num     => @line_num,
          }
        end
      else
        @rules[:plain_override] << {
          :domain       => domain,
          :domain_regex => "=#{domain}",
          :alias        => domain,
          :path         => Regexp.quote(path),
          :path_regex   => '^/' + Regexp.quote(path) + '$',
          :dest         => dest_info[:dest],
          :dest_domain  => dest_info[:domain],
          :line_num     => @line_num,
        }
      end
    end

    # Interpret a <dest> token and return information about it. See the comment
    # in redirects.dat for information about forms it can take.
    def interpret_dest(dest)
      if @web_server == 'apache'
        escape_char = '\\%'
        same_proto_redirect = '%{ENV:RW_PROTO}:'
      else
        escape_char = '%'
        same_proto_redirect = '$scheme:'
      end
      dest = dest.gsub(/[^\p{ASCII}]/) do |c|
        escape_char + c.unpack('H2' * c.bytesize).join(escape_char).upcase
      end
      case dest
      when %r{^(https?://)([^/]*)(/.*$|$)}
        domain = Regexp.last_match[2]
        path = Regexp.last_match[3]
        dest += '/' if path.empty?
      when %r{^//([^/]*)(/.*$|$)}
        dest = same_proto_redirect + dest
        domain = Regexp.last_match[1]
        path = Regexp.last_match[2]
        dest += '/' if path.empty?
      else
        error("destination must be either a protocol-relative or a fully-specified URL")
      end
      {:dest => dest, :domain => domain}
    end

    # Interpret a source domain wildcard and return information about it.
    def interpret_wildcard(wildcard)
      case wildcard
      when /^\*\.([^*]*)/
        [{
          :domain_regex => '^(.+)\.' << Regexp.quote(Regexp.last_match[1]) << '$',
          :alias        => wildcard,
        }]
      when /^\*([^*]*)/
        [{
          :domain_regex => '=' + Regexp.last_match[1],
          :alias        => Regexp.last_match[1],
        }, {
          :domain_regex => '^(.+)\.' << Regexp.quote(Regexp.last_match[1]) << '$',
          :alias        => '*.' << Regexp.last_match[1],
        }]
      when /\*/
        error("invalid use of asterisk in domain pattern")
      else
        [{
          :domain_regex => '=' + wildcard,
          :alias        => wildcard,
        }]
      end
    end

    # Check to see if any override rules were given which didn't have an
    # associated funnel or rewrite, and raise an error if any are found.
    def check_orphan_overrides
      servers = @rules.values_at(:wildcard, :plain).flatten
      aliases = servers.map { |rule| rule[:alias] }
      overrides = @rules.values_at(:wildcard_override, :plain_override).flatten
      overrides.each do |rule|
        unless aliases.include? rule[:alias]
          error("override must have an associated funnel or rewrite", rule[:line_num])
        end
      end
    end

    # Check for double or infinite redirects and raise an error if any are found.
    def check_loops
      flat_rules = @rules.values.flatten
      flat_rules.each do |outbound_rule|
        flat_rules.each do |inbound_rule|
          outbound_domain = outbound_rule[:dest_domain]
          inbound_domain = inbound_rule[:domain]
          inbound_regex = inbound_rule[:domain_regex]
          if outbound_domain =~ /#{@group_dest.sub('$', '\$')}/
            if inbound_domain.end_with? $'
              error("double redirect: rule has destination domain #{outbound_domain} "\
                    "which matches relevant suffix of source domain '#{inbound_domain}' "\
                    "from line #{inbound_rule[:line_num]}", outbound_rule[:line_num])
            end
          elsif inbound_regex[0] == '='
            if inbound_domain == outbound_domain
              error("double redirect: rule has destination domain #{outbound_domain} "\
                    "from line #{inbound_rule[:line_num]}", outbound_rule[:line_num])
            end
          elsif outbound_domain =~ /#{inbound_regex}/
            error("double redirect: rule has destination domain #{outbound_domain} "\
                  "which matches wildcard #{inbound_domain} from line #{inbound_rule[:line_num]}",
                  outbound_rule[:line_num])
          end
        end
      end
    end

    def write_nginx_conf(dest)
      dest.puts "map $host $rewrite {\n\thostnames;\n"
      [:plain, :wildcard].each do |type|
        lower_camel_name = type.to_s.gsub(/_(\w)/) { Regexp.last_match[1].upcase }
        dest.puts "\n\t# Type: #{lower_camel_name}\n"
        @rules[type].each do |rule|
          dest.puts "\t# #{@lines[rule[:line_num] - 1]}"
          if rule[:dest] =~ /#{@group_dest.sub('$', '\$')}/
            dest.puts "\t~#{rule[:domain_regex]}\t#{rule[:dest]};"
          else
            dest.puts "\t#{rule[:alias]}\t#{rule[:dest]};"
          end
        end
      end
      dest.puts "}\n"

      dest.puts "map $host$uri $override {\n\thostnames;\n"
      [:plain_override, :wildcard_override].each do |type|
        lower_camel_name = type.to_s.gsub(/_(\w)/) { Regexp.last_match[1].upcase }
        dest.puts "\n\t# Type: #{lower_camel_name}\n"
        @rules[type].each do |rule|
          dest.puts "\t# #{@lines[rule[:line_num] - 1]}"
          if rule[:dest] =~ /#{@group_dest.sub('$', '\$')}/
            dest.puts "\t~#{rule[:domain_regex]}\t#{rule[:dest]};"
          else
            dest.puts "\t#{rule[:alias]}/#{rule[:path]}\t#{rule[:dest]};"
          end
        end
      end
      dest.puts "}"
      dest
    end

    # Write the collected rules to the output file.
    def write_apache_conf(dest)
      dest.puts <<-eos.gsub(/^ {8}/, '')
        # This file is generated automatically by Puppet
        # Do not edit it manually!

        <VirtualHost *:80>
        \tServerName redirector

      eos

      servers = @rules.values_at(:wildcard, :plain).flatten.map { |rule| rule[:alias] }
      servers.uniq.each { |server| dest.puts "\tServerAlias #{server}\n" }

      dest.puts <<-eos.gsub(/^ {8}/, "\t")

        # allow caching for redirects
        <IfModule mod_headers.c>
        \tHeader set Cache-control "s-maxage=86000, max-age=0, must-revalidate"
        </IfModule>
        <IfModule mod_expires.c>
        \tExpiresActive On
        \tExpiresByType image/gif A2592000
        \tExpiresByType image/png A2592000
        \tExpiresByType image/jpeg A2592000
        \tExpiresByType text/css A2592000
        \tExpiresByType text/javascript A2592000
        \tExpiresByType application/x-javascript A2592000
        \tExpiresByType text/html A2592000
        </IfModule>

        DocumentRoot /srv/mediawiki/docroot/default

        RewriteEngine On

        RewriteRule . - [E=RW_PROTO:%{HTTP:X-Forwarded-Proto}]
        RewriteCond %{ENV:RW_PROTO} !=https
        RewriteRule . - [E=RW_PROTO:http]
      eos

      # Write more specific rules first, followed by less specific rules
      [:plain_override, :wildcard_override, :plain, :wildcard].each do |type|
        lower_camel_name = type.to_s.gsub(/_(\w)/) { Regexp.last_match[1].upcase }
        dest.puts "\n\t# Type: #{lower_camel_name}\n"
        @rules[type].each do |rule|
          dest.puts <<-eos.gsub(/^ {12}/, "\t")
            # #{@lines[rule[:line_num] - 1]}
            RewriteCond %{HTTP_HOST} #{rule[:domain_regex]}
            RewriteRule #{rule[:path_regex]} #{rule[:dest]} [R=301,L,NE]
          eos
        end
      end

      dest.puts <<-eos.gsub(/^ {8}/, '')
        </VirtualHost>
        # vim: sts=4 sw=4 autoindent syn=apache
      eos
      dest
    end
  end

  class ParserError < StandardError
    def initialize(msg, line_num = nil)
      @line_num = line_num
      super(msg)
    end

    def to_s
      @line_num.nil? ? super : "[line #{@line_num}]: #{super}"
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  abort "Usage: #{$PROGRAM_NAME} DAT_FILE [apache|nginx]" if ARGV.length < 1 || ARGV.length > 2
  if ARGV.length == 1
    web_server = 'apache'
  else
    web_server = ARGV[1]
  end
  parser = DomainRedirects::Parser.new(File.read(ARGV[0]), web_server)
  parser.parse_to(STDOUT)
  exit 0
end

module Puppet::Parser::Functions
  newfunction(:compile_redirects, :type => :rvalue) do |args|
    raise Puppet::ParseError, 'compile_redirects() requires at least one argument' if args.length < 1 || args.length > 2
    Puppet::Parser::Functions.autoloader.loadall
    input = case args.first
            when %r{^puppet://.*} then Puppet::FileServing::Content.indirection.find($&).content.force_encoding("utf-8")
            when %r{^/} then function_file(args)
            else args.first
            end
    if args.length == 1
      web_server = 'apache'
    else
      web_server = args[1]
    end
    parser = DomainRedirects::Parser.new(input, web_server)
    parser.parse
  end
end
