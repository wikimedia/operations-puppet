require 'erb'
require 'minitest/autorun'

class TestTemplates < MiniTest::Unit::TestCase

    attr_accessor :desc, :proto, :port, :srange

    def setup
        @erb = ERB.new(File.read(
            File.join(File.dirname(__FILE__),
                      '../../templates/service.erb')),
            nil, '-')
        @desc = 'Dummy description'
    end

	def test_srange_string_single_address
        @srange = '127.0.0.1'
        assert_includes(@erb.result(binding).split(/\n/),
                        '&R_SERVICE(, , 127.0.0.1);')
	end

	def test_srange_string_multiple_addresses
        @srange = '127.0.0.1 198.51.100.42'
        assert_includes(@erb.result(binding).split(/\n/),
                        '&R_SERVICE(, , 127.0.0.1 198.51.100.42);')
	end

	def test_srange_array_single_address
        @srange = ['127.0.0.1']
        assert_includes(@erb.result(binding).split(/\n/),
                        '&R_SERVICE(, , 127.0.0.1);')
	end

	def test_srange_array_of_addresses
        @srange = ['127.0.0.1', '198.51.100.42']
        assert_includes(@erb.result(binding).split(/\n/),
                        '&R_SERVICE(, , 127.0.0.1);')
	end
end
