# == Function: slice_network_constants(realm)
#
# Return a specific port of network::subnets as a
# flattened array.
# Optionally return only a specific sphere (public/private)
# Optionally return only an address family
# Optionally return only subnets matching a regexp in their description
#
# == Arguments
# realm needs to be a key in network::subnets
# Second argument is an optional hash with the following (all optional) keys
# that will act as filters on the returned data, limiting the amount of data
# returned. If any is not specified, there will not be any filtering for that
# key
#
# sphere: public/private accepted
# af: address family: ipv4/ipv6 accepted
# site: a site as defined by the global $::site variable
# description: a string. Will be used as a regexp to be matched against network
# strings
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
# slice_network_constants('production', { 'sphere' => 'public', 'site' => 'eqiad' })
#
# # Get analytics production networks
# slice_network_constants('production', { 'description' => 'analytics' })
#
module Puppet::Parser::Functions
  newfunction(:slice_network_constants, :type => :rvalue, :arity => -2) do |args|
    fail ArgumentError, 'slice_network_constants() requires an argument' if args.empty?
    fail ArgumentError, 'slice_network_constants() cannot handle more than 2 values' if args.length > 2
    all_network_subnets = function_hiera(['network::subnets'])
    realm = args[0]
    options = args[1] if args.length > 1
    requested_site = options['site'] if options
    requested_sphere = options['sphere'] if options
    af = options['af'] if options
    description = options['description'] if options

    if !all_network_subnets.key?(realm)
        fail ArgumentError, 'slice_network_constants() realm non existant in network::subnets'
    end
    if requested_site && (!all_network_subnets[realm].key? requested_site)
        fail ArgumentError, "slice_network_constants() site specified must be present in network::subnets[#{realm}]. #{requested_site} was provided"
    end
    if requested_sphere && (!['public', 'private'].include? requested_sphere)
        fail ArgumentError, "slice_network_constants() sphere can only be public/private. #{requested_sphere} was provided"
    end
    if af && (!['ipv4', 'ipv6'].include? af)
        fail ArgumentError, "slice_network_constants() address family specified can only be ipv4 or ipv6. #{af} was provided"
    end

    # And let's get our data back
    result = all_network_subnets[realm].collect { |site, value_site|
        if requested_site && site != requested_site
            next
        end
        value_site.collect { |sphere, value_sphere|
            if requested_sphere && sphere != requested_sphere
                next
            end
            value_sphere.collect { |subnet, value_subnet|
                if description && !(/#{description}/ =~ subnet)
                    next
                end
                if af
                    value_subnet[af]
                else
                    # flatten will take care of this below
                    [value_subnet['ipv4'], value_subnet['ipv6']]
                end
            }
        }
    }
    result.flatten.compact.sort
  end
end
