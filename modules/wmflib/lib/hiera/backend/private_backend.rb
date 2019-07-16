class Hiera
  module Backend
    # This naming is required by puppet.
    class Private_backend
      # This is not a real backend.  We abuse the backend functionality so we
      # can dynamicly change 'datadirs' in the nuyaml3 backend based on the
      # directory prefix 'private/'
      def lookup(_key, _scope, _order_override, _resolution_type)
        throw(:no_such_key)
      end
    end
  end
end
