require 'spec_helper'

describe 'secret' do
  it 'should throw an error if the file is not existent' do
    is_expected.to run.with_params('test/text1').and_raise_error(ArgumentError)
  end

  it 'should run correctly with a good filename' do
    is_expected.to run.with_params('test/test.txt').and_return("42\n")
  end

  it 'should throw an error if the number of arguments is wrong' do
    is_expected.to run.with_params('a', 'b').and_raise_error(ArgumentError)
    is_expected.to run.with_params(12).and_raise_error(ArgumentError)
    is_expected.to run.and_raise_error(ArgumentError)
  end
end
