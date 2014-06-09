# encoding: utf-8
#
# == Function: compile_redirects
#
# This is a Ruby compiler for a mini-language for URL rewriting schemes.
# The output it generates is an Apache config file. The syntax was invented by
# Tim Starling to eliminate common sources of errors.
#
# See <http://git.io/2VHlCg> for a full description.
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

    def initialize(source)
      @lines = source.lines.map(&:rstrip)
      @rules = {
        :wildcard          => [],
        :plain             => [],
        :wildcard_override => [],
        :plain_override    => [],
      }
    end

    def parse
      @lines.each_with_index do |line,num|
        @line_num = num + 1
        args = line.gsub(/#.*/, '').strip.split
        send(*args) unless args.empty?
      end
      check_orphan_overrides
      check_loops
      write_apache_conf
    end

    def error(msg, line_num = @line_num)
      raise DomainRedirects::ParserError.new(msg, line_num)
    end

    # Process a funnel command at the current input position
    # @param array args The arguments to the command
    def funnel(domain, dest)
      dest_info = interpret_dest(dest)
      if domain.include? '*' then
        wildcard_list = interpret_wildcard(domain)
        wildcard_list.each do |wildcard|
          domain_regex = wildcard[:domain_regex]
          if domain_regex.include? '(' then
            wildcard_dest = dest_info[:dest].gsub('*', '%1')
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
    # @param array args The arguments to the command
    def rewrite(domain, dest)
      dest_info = interpret_dest(dest)
      dest_info[:dest].sub!(/\/$/, '')
      if domain.include? '*' then
        wildcard_list = interpret_wildcard(domain)
        wildcard_list.each do |wildcard|
          domain_regex = wildcard[:domain_regex]
          wildcard_dest = dest_info[:dest]
          wildcard_dest.gsub!('*', '%1') if domain_regex.include? '('
          @rules[:wildcard] << {
            :domain       => domain,
            :domain_regex => domain_regex,
            :alias        => wildcard[:alias],
            :path_regex   => '.*',
            :dest         => "#{wildcard_dest}$0",
            :dest_domain  => dest_info[:domain],
            :line_num     => @line_num,
          }
        end
      else
        @rules[:plain] << {
          :domain       => domain,
          :domain_regex => "=#{domain}",
          :alias        => domain,
          :path_regex   => '.*',
          :dest         => dest_info[:dest] + '$0',
          :dest_domain  => dest_info[:domain],
          :line_num     => @line_num,
        }
      end
    end

    # Process an override command at the current input position
    # @param array args The arguments to the command
    def override(source, dest)
      dest_info = interpret_dest(dest)
      domain, path = source.split('/', 2)
      error('the source of an override must include a path component') if path.nil?
      if domain.include? '*' then
        wildcard_list = interpret_wildcard(domain)
        wildcard_list.each do |wildcard|
          domain_regex = wildcard[:domain_regex]
          if domain_regex.include? '(' then
            wildcard_dest = dest_info[:dest].gsub('*', '%1')
          else
            wildcard_dest = dest_info[:dest]
          end
          @rules[:wildcard_override] << {
            :domain       => domain,
            :domain_regex => domain_regex,
            :alias        => wildcard[:alias],
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
      # Escape non-ASCII characters
      dest = dest.gsub(/[^\p{ASCII}]/) do |c|
        '\\%' + c.unpack('H2' * c.bytesize).join('\\%').upcase
      end
      case dest
      when %r!^(https?://)([^/]*)(/.*$|$)!
        domain = $2
        path = $3
        dest += '/' if path.empty?
      when %r!^//([^/]*)(/.*$|$)!
        dest = '%{ENV:RW_PROTO}:' + dest
        domain = $1
        path = $2
        dest += '/' if path.empty?
      else
        error("destination must be either a protocol-relative or a fully-specified URL")
      end
      return {:dest => dest, :domain => domain}
    end

    # Interpret a source domain wildcard and return information about it.
    def interpret_wildcard(wildcard)
      case wildcard
      when /^\*\.([^*]*)/
        [{
          :domain_regex => '^(.+)\.' + Regexp.quote($1) + '$',
          :alias        => wildcard,
        }]
      when /^\*([^*]*)/
        [{
          :domain_regex => '=' + $1,
          :alias        => $1,
        }, {
          :domain_regex => '^(.+)\.' + Regexp.quote($1) + '$',
          :alias        => '*.' + $1,
        }]
      when /^([^*]*)\.\*\.([^*]*)/
        [{
          :domain_regex => '^' + Regexp.quote($1) + '\.(.+)\.' + Regexp.quote($2) + '$',
          :alias        => wildcard,
        }]
      when /\*/
        error("invalid use of asterisk in domain pattern")
      else
        [{
          :domain_regex => '=' + wildcard,
          :alias        => wildcard
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
        error(
          "override must have an associated funnel or rewrite",
          rule[:line_num]
        ) unless aliases.include? rule[:alias]
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
          wildcard_pos = outbound_domain.index('%1')
          if outbound_domain =~ /%1/ then
            error(
              "double redirect: rule has destination domain "\
              "#{outbound_domain} which matches relevant suffix of source "\
              "domain '#{inbound_domain}' from line #{inbound_rule[:line_num]}",
              outbound_rule[:line_num]
            ) if inbound_domain.end_with? $'
          elsif inbound_regex[0] == '=' then
            error(
              "double redirect: rule has destination domain "\
              "#{outbound_domain} from line #{inbound_rule[:line_num]} ",
              outbound_rule[:line_num]
            ) if inbound_domain == outbound_domain
          elsif outbound_domain =~ /#{inbound_regex}/ then
            error(
              "double redirect: rule has destination domain "\
              "#{outbound_domain} which matches wildcard #{inbound_domain} "\
              "from line #{inbound_rule[:line_num]}",
              outbound_rule[:line_num]
            )
          end
        end
      end
    end

    # Write the collected rules to the output file.
    def write_apache_conf
      StringIO.open do |file|
        file.puts DomainRedirects.indent 0, <<-eos
          # This file is generated by Puppet from a source file
          # Do not edit it manually!

          <VirtualHost *>
          \tServerName redirector
          \tServerAlias \\
        eos

        servers = @rules.values_at(:wildcard, :plain).flatten.map do |rule|
            rule[:alias]
        end

        servers.uniq.each do |server|
          file.puts "\t#{server} \\\n"
        end

        file.puts DomainRedirects.indent 1, <<-eos

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

          DocumentRoot /usr/local/apache/common/docroot/default

          RewriteEngine On

          RewriteRule . - [E=RW_PROTO:%{HTTP:X-Forwarded-Proto}]
          RewriteCond %{ENV:RW_PROTO} !=https
          RewriteRule . - [E=RW_PROTO:http]
        eos

        # Write more specific rules first, followed by less specific rules
        [:plain_override, :wildcard_override, :plain, :wildcard].each do |type|
          lower_camel_name = type.to_s.gsub(/_(\w)/) { $1.upcase }
          file.puts "\n\t# Type: #{lower_camel_name}\n"
          @rules[type].each do |rule|
            file.puts DomainRedirects.indent 1, <<-eos
              # #{@lines[rule[:line_num] - 1]}
              RewriteCond %{HTTP_HOST} #{rule[:domain_regex]}
              RewriteRule #{rule[:path_regex]} #{rule[:dest]} [R=301,L,NE]
            eos
          end
        end

        file.puts DomainRedirects.indent 0, <<-eos
          </VirtualHost>
          # vim: sts=4 sw=4 autoindent syn=apache
        eos
        file.rewind
        file.read
      end
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

  module_function
  def indent(level, s)
    leading = s.scan(/^ */).sort.uniq
    leading.push(leading.shift) or ''
    s.gsub(/^ {#{leading.first.length}}/, "\t" * level)
  end
end

if __FILE__ == $0
  abort "Usage: #{$0} DAT_FILE" if ARGV.empty?
  parser = DomainRedirects::Parser.new(File.read(ARGV.shift))
  puts parser.parse
  exit 0
end

module Puppet::Parser::Functions
  newfunction(:compile_redirects, :type => :rvalue) do |args|
    if args.length != 1
      raise Puppet::ParseError, 'compile_redirects() takes one argument'
    end

    Puppet::Parser::Functions.autoloader.loadall

    input = case args.first
    when %r(^puppet://.*) then Puppet::FileServing::Content.indirection.find($&).content
    when %r(^/) then function_file(args)
    else args.first
    end

    parser = DomainRedirects::Parser.new(input)
    parser.parse
  end
end
