class Hiera
  module Backend
    # This naming is required by puppet.
    class Netbox_backend
      # This is not a real backend.  We abuse the backend functionality so we
      # can dynamically change 'datadirs' in the nuyaml3 backend based on the
      # directory prefix 'netbox/'
      def lookup(_key, _scope, _order_override, _resolution_type, _context)
        throw(:no_such_key)
      end
    end
  end
end
