module Matchers

    class AutoRequireMatcher
        def initialize(*expected)
            @expected = expected
        end

        def matches?(resource)
            resource_type = resource.class
            configuration = resource_type.instance_variable_get(:@autorequires) || {}
            @autorequires = configuration.inject([]) do |memo, (param, block)|
                memo + resource.instance_eval(&block)
            end
            @autorequires.include?(@expected)
        end
        def failure_message_for_should
            "expected resource autorequires (#{@autorequires.inspect}) to include #{@expected.inspect}"
        end
        def failure_message_for_should_not
            "expected resource autorequires (#{@autorequires.inspect}) to not include #{@expected.inspect}"
        end
    end

    # call-seq:
    #   autorequire :logical_volume, 'mylv'
    def autorequire(type, name)
        AutoRequireMatcher.new(type, name)
    end
    
end
