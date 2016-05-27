# == Function: slice_network_constants(realm)
#
# Return a specific port of network::constants::all_network_subnets as a
# flattened array.
# Optionally return only a specific sphere (public/private) by passing an
# optional second argument
# Optionally return only an address family, but passing ipv4 or ipv6 as an
# optional third argument
# realm needs to be a key in networks::constants::all_network_subnets
# sphere has to be public/private, defaults to both if not specified.
# address family needs to be ipv4 or ipv6, defaults to both if not specified
#
# == Examples
# # Get all ipv4 subnets that belong in production, public sphere
# slice_network_constants('production', 'public', 'ipv4')
#
# # Get IPv4/IPv6 subnets that belong in labs
# slice_network_constants('labs')
#
# # Get private only production networks
# slice_network_constants('labs', 'private')
#
module Puppet::Parser::Functions
  newfunction(:slice_network_constants, :type => :rvalue) do |args|
    fail 'slice_network_constants() requires an argument' if args.empty?
    fail 'slice_network_constants() cannot handle more than 3 values' if args.length > 3
	all_network_subnets = lookupvar('network::constants::all_network_subnets')
	realm = args[0]
	sphere = args[1] if args.length > 1
	af = args[2] if args.length > 2

    # Make sure we got sane arguments
	if sphere && (sphere != 'public' && sphere != 'private')
		fail 'slice_network_constants() sphere can only be public/private'
	end
	if af && (af != 'ipv4' && af != 'ipv6')
		fail 'slice_network_constants() address family specified can only be "ipv4" or "ipv6"'
	end
    if not all_network_subnets.key?(realm)
		fail 'slice_network_constants() realm non existant in networks::constants::all_network_subnets'
    end

    # And let's get our data back
	result = all_network_subnets[realm].collect { |site, value_site|
		value_site.collect { |sphere, value_sphere|
			value_sphere.collect { |subnet, value_subnet|
				if af
					value_subnet[af]
				else
                    # flatten will take care of this below
					[value_subnet['ipv4'], value_subnet['ipv6']]
				end
			}
		}
	}
	result = result.flatten.compact
  end
end
