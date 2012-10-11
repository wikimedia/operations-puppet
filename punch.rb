#!/usr/bin/env ruby -W0
# -*- coding: utf-8 -*-
#
# Parse Puppet manifests into JSON
#
# Usage: punch.rb [--hostclass HOSTCLASS] manifest.pp
#   --help, -h         Show this help and exit
#   --ignore-import    Do not attempt to parse depdencies
#   --hostclass, -c    Output only this host class (default: all)
#
# Example:
#   punch -c 'role::cache::configuration' site.pp
#
# Author: Ori Livneh <ori@wikimedia.org>
#

require 'getoptlong'
require 'json'
require 'puppet'


include Puppet::Parser


def parse_file(manifest, ignore_import=false)
    pp = Puppet::Parser::Parser.new('')
    if ignore_import
        pp.file = manifest
        Puppet[:ignoreimport] = true
        ast = pp.parse
        pp.known_resource_types.import_ast(ast, manifest)
    else
        pp.import(manifest)
    end
    return pp
end

# Public: Recursively convert a Puppet AST object to primitive Ruby
# types.
#
# When no equivalent primitive exists, converts to a hash of instance
# variables, omitting :@line, :@file_index and :@children, and adding
# a key, "type", with the node's class name as the value.
#
# Returned object is JSON-serializable.
#
def primitive(node)
    case node
    when Array
        node.map { |child| primitive(child) }
    when Hash
        hash = {}
        node.each { |k,v| hash[primitive(k)] = primitive(v) }
        hash
    when Regexp
        node.to_s
    when Puppet::Resource::Type
        primitive(node.code)
    when AST::ASTArray
        primitive(node.children)
    when AST::Boolean
        node.value == "true"
    when AST::Concat, AST::ASTHash
        primitive(node.value)
    when AST::Hostclass
        { node.name => primitive(node.code) }
    when AST::Name, AST::String, AST::Type
        node.value
    when AST
        hash = { 'type' => node.class.to_s }
        vars = node.instance_variables - [:@line, :@file_index, :@children]
        vars.each do |var|
            k = var.to_s[1..-1]
            v = node.instance_variable_get(var)
            hash[k] = primitive(v)
        end
        hash
    else
        node
    end
end


def show_usage
    puts <<-END.gsub(/^ {4}/, '')
    Parse Puppet manifests into JSON

    Usage: #{$0} [--hostclass HOSTCLASS] manifest.pp
      --help, -h         Show this help and exit
      --ignore-import    Do not attempt to parse depdencies
      --hostclass, -c    Output only this host class (default: all)

    Example:
      punch -c 'role::cache::configuration' site.pp

    END
    exit 1
end


if __FILE__ == $0
    hclass = nil
    ignore_import = false

    opts = GetoptLong.new(
      [ '--help',           '-h',  GetoptLong::NO_ARGUMENT ],
      [ '--hostclass',      '-c',  GetoptLong::OPTIONAL_ARGUMENT ],
      [ '--ignore-import',  '-i',  GetoptLong::NO_ARGUMENT ]
    )

    opts.each do |opt, arg|
        case opt
        when '--help'
            show_usage
        when '--hostclass'
            hclass = arg
        when '--ignore-import' 
            ignore_import = true
        end
    end

    manifest = ARGV.shift
    show_usage unless manifest

    begin
        pp = parse_file(manifest, ignore_import)
    rescue Puppet::ParseError => e
        $stderr.puts e.message
        abort( "Invoke punch.rb with \"--ignore-import\" to override." )
    end

    if hclass != nil
        root = pp.find_hostclass('', hclass)
    else
        root = pp.known_resource_types.hostclasses
    end

    prim = primitive(root)
    puts JSON.pretty_generate(prim, :max_nesting => false)
end
