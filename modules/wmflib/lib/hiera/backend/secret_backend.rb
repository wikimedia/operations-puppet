class Hiera
  module Backend
    # This naming is required by puppet.
    class Secret_backend
      # This is not a real backend.  We abuse the backend functionality so we
      # can dynamicly change 'datadirs' in the nuyaml3 backend based on the
      # directory prefix 'secret/'
      def lookup(_key, _scope, _order_override, _resolution_type); end
    end
  end
end
