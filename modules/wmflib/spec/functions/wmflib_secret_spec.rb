require 'spec_helper'

describe 'wmflib::secret' do
  it 'should throw an error if the file is not existent' do
    is_expected.to run.with_params('test/text1').and_raise_error(
      ArgumentError, %r{secret\(\): invalid secret test/text1}
    )
  end

  it 'should run correctly with a good filename' do
    is_expected.to run.with_params('test/test.txt').and_return("42\n")
  end
  it 'should run correctly with a good filename (setting binary: false)' do
    is_expected.to run.with_params('test/test.txt', false).and_return("42\n")
  end
  it 'should run correctly with a good filename (setting binary: true)' do
    is_expected.to run.with_params('test/test.txt', true).and_return(
      Puppet::Pops::Types::PBinaryType::Binary.from_string("42\n")
    )
  end

  it 'should throw an error if the second argument not binary' do
    is_expected.to run.with_params('a', 'b').and_raise_error(
      ArgumentError, /'binary' expects a Boolean value/
    )
  end
end
