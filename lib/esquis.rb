require 'tempfile'
require 'pp'

require 'esquis/props'

require 'esquis/ast'
require 'esquis/parser'

module Esquis
  def self.compile(src)
    ast = Parser.new.parse(src)
    return ast.to_ll
  end

  def self.run(src)
    ll = compile(src)
    #puts ll
    temp = Tempfile.new
    temp.write(ll)
    temp.close
    return `lli #{temp.path}`
  end
end
