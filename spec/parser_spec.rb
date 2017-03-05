require 'spec_helper'

describe "Parser" do
  def parse(src)
    Esquis::Parser.new.parse(src)
  end

  it "should allow trailing space on a line" do
    expect {
      parse("class A \nend\n1+1")
    }.not_to raise_error
  end
end
