require 'esquis/ast'

module Esquis
  module Stdlib
    include Esquis::Ast

    LL_STDLIB = <<~'EOD'
      declare i32 @printf(i8*, ...)
      ;declare i32 @putchar(i32)

      @putd_tmpl = private unnamed_addr constant [3 x i8] c"%d\00"
      define void @putd(i32 %num) {
        %putd1 = getelementptr inbounds [3 x i8], [3 x i8]* @putd_tmpl, i32 0, i32 0
        call i32 (i8*, ...) @printf(i8* %putd1, i32 %num)
        ret void
      }

      @putf_tmpl = private unnamed_addr constant [3 x i8] c"%f\00"
      define void @putf(double %num) {
        %putf1 = getelementptr inbounds [3 x i8], [3 x i8]* @putf_tmpl, i32 0, i32 0
        call i32 (i8*, ...) @printf(i8* %putf1, double %num)
        ret void
      }

      ;define void @putc(i32 %c) {
      ;  call i32 @putchar(i32 %c)
      ;  ret void
      ;}
    EOD

    TOPLEVEL_FUNCS = {
      "putd" => Extern.new("Void", "putd", [Param.new("n", "i32")]),
      "putf" => Extern.new("Void", "putf", [Param.new("n", "double")]),
      #"putc" => Extern.new("Void", "putc", [Param.new("c", "i32")]),
    }

    TOPLEVEL_FUNCS.each do |k, v|
      v.add_type!(Env.new)
    end
  end
end
