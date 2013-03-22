#!/usr/bin/env ruby
#
# This script let you expand an ERB template from the command line
# while optionally passing variables that will be expanded in the
# template.
#
# Joint copyright:
# Copyright 2012, Antoine "hashar" Musso
# Copyright 2012, Wikimedia Foundation

# Command line option parsing library
require 'optparse'
require 'erb'

# Filename of the ERB template we are going to expand
$filename = nil

# Parsing the options
optparse = OptionParser.new do |opts|

	opts.banner = "Usage: expanderb.rb -f FILENAME [key=val [key2=val]]"

	opts.on( '-f', '--filename FILENAME', 'ERB filename to expand') do |f|
		$filename = f
	end

	opts.on_tail( '-h', '--help', 'Show this message' ) do
		puts opts
		exit
	end
end

# Parse command line options
begin
	# -f is mandatory
	optparse.parse!
	if $filename.nil?
	 	puts "You must specify an ERB filename"
		puts optparse
		exit
	end
rescue
	# Catch all
	puts $!.to_s
	puts optparse
	exit
end

template_values = {}
ARGV.each do |val|
	key, value = val.split( '=' )
	template_values[key] = value
end
p template_values

def get_values(key)
	template_values[key]
end


# Parse template
begin
	template = ERB.new(File.read($filename))
	p template.result(get_values)
rescue
	p "Something went wrong, usually because you are missing a variable."
	p $!.to_s
end
