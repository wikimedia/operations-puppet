# == Function: slice_network_constants(realm)
#
# Return a specific port of network::constants::all_network_subnets as a
# flattened array.
# Optionally return only a specific sphere (public/private)
# Optionally return only an address family
#
# == Arguments
# realm needs to be a key in networks::constants::all_network_subnets
# Second argument is an optional hash with the following (all optional) keys
# that will act as filters on the returned data, limiting the amount of data
# returned. If any is not specified, there will not be any filtering for that
# key
#
# sphere: public/private accepted
# af: address family: ipv4/ipv6 accepted
# site: a site as defined by the global $::site variable
#
# == Examples
# # Get all subnets that belong in production
# slice_network_constants('production')
#
# # Get IPv4 subnets that belong in labs
# slice_network_constants('labs', { 'af' => 'ipv4' })
#
# # Get private only production networks
# slice_network_constants('production', { 'sphere' => 'private' })
#
# # Get public+eqiad only production networks
# slice_network_constants('production', { 'sphere' => 'public', 'site' => # 'eqiad' })
#
module Puppet::Parser::Functions
  newfunction(:slice_network_constants, :type => :rvalue, :arity => -2) do |args|
    fail 'slice_network_constants() requires an argument' if args.empty?
    fail 'slice_network_constants() cannot handle more than 2 values' if args.length > 2
    all_network_subnets = function_hiera(['network::all_network_subnets'])
    realm = args[0]
    options = args[1] if args.length > 1
    requested_sphere = options['sphere'] if options.key? 'sphere'
    af = options['af'] if options.key? 'af'
    requested_site = options['site'] if options.key? 'site'

    # Make sure we got sane arguments
    # Disable rubocop's check for usage of &&/|| instead of and/or. In this
    # example using &&/|| returns an expression instead of a boolean which
    # always evaluates to true, causing the checks to fail. The same goes for
    # the other 2 lines with and terms
    # rubocop:disable Style/AndOr
    if defined? requested_sphere and !['public', 'private'].include? requested_sphere
        fail "slice_network_constants() sphere can only be public/private. #{requested_sphere} was provided"
    end
    if defined? af and !['ipv4', 'ipv6'].include? af
        fail "slice_network_constants() address family specified can only be ipv4 or ipv6. #{af} was provided"
    end
    if !all_network_subnets.key?(realm)
        fail 'slice_network_constants() realm non existant in networks::constants::all_network_subnets'
    end
    if defined? requested_site and !all_network_subnets[realm].key? requested_site
        fail "slice_network_constants() site specified must be present in all_network_subnets[#{realm}]. #{requested_site} was provided"
    end

    # And let's get our data back
    result = all_network_subnets[realm].collect { |site, value_site|
        if defined? requested_site and site != requested_site
            next
        end
        value_site.collect { |sphere, value_sphere|
            if defined? requested_sphere and sphere != requested_sphere
                next
            end
            value_sphere.collect { |_, value_subnet|
                if defined? af
                    value_subnet[af]
                else
                    # flatten will take care of this below
                    [value_subnet['ipv4'], value_subnet['ipv6']]
                end
            }
        }
    }
    # rubocop:disable Style/AndOr
    result.flatten.compact
  end
end
