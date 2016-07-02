require 'spec_helper'

describe "the ensure_mounted function" do
  it "should exist" do
    expect(Puppet::Parser::Functions.function("ensure_mounted")).to eq("function_ensure_mounted")
  end

  it "should raise a ParseError if there are less than 1 arguments" do
    expect {
      scope.function_ensure_mounted([])
    }.to raise_error(ArgumentError)
  end

  it "should raise a ParseError if there are more than 1 arguments" do
    expect {
      scope.function_ensure_mounted(['a', 'b'])
    }.to raise_error(ArgumentError)
  end

  it "should return 'mounted' for param 'present'" do
    expect(scope.function_ensure_mounted(['present'])).to eq('mounted')
  end

  it "should return 'mounted' for param 'true'" do
    expect(scope.function_ensure_mounted([true])).to eq('mounted')
  end

  it "should return 'absent' for param 'absent'" do
    expect(scope.function_ensure_mounted(['absent'])).to eq('absent')
  end

  it "should return 'false' for param 'false'" do
    expect(scope.function_ensure_mounted([false])).to eq(false)
  end

end
