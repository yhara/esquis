require 'tempfile'
require 'pp'

require 'esquis/props'

require 'esquis/ast'
require 'esquis/stdlib'
require 'esquis/type'
require 'esquis/parser'

module Esquis
  def self.compile(src)
    ast = Parser.new.parse(src)
    return ast.to_ll_str
  end

  def self.run(src, src_path: nil, capture: false)
    ll = compile(src)

    if src_path
      base = File.join(File.dirname(src_path),
                       File.basename(src_path, ".es"))
      ll_path = base + ".ll"
      File.write(ll_path, ll)
      s_path = base + ".s"
      exe_path = base + ".out"
    else
      temp_ll = Tempfile.new(["esquis.", ".ll"])
      temp_ll.write(ll)
      temp_ll.close
      ll_path = temp_ll.path
      temp_s = Tempfile.new(["esquis.", ".s"])
      temp_s.close
      s_path = temp_s.path
      temp_exe = Tempfile.new(["esquis.", ".out"])
      temp_exe.close
      exe_path = temp_exe.path
    end

    system "llc", ll_path, "-o", s_path
  	system "cc",
      "-I", "/usr/local/Cellar/bdw-gc/7.6.0/include/",
	    "-L", "/usr/local/Cellar/bdw-gc/7.6.0/lib/",
      "-l", "gc",
      "-g",
      "-o", exe_path,
      s_path

    if capture
      return `#{exe_path}`
    else
      system exe_path
    end
  end
end
