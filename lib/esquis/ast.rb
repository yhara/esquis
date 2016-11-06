module Esquis
  class Ast
    class Node
      extend Props

      def self.reset
        @@reg = 0
        @@if = 0
        @@for = 0
      end
      reset

      def newreg
        @@reg += 1
        return "%reg#{@@reg}"
      end

      def newif
        return (@@if += 1)
      end

      def newfor
        return (@@for += 1)
      end
    end

    class Program < Node
      props :defs, :main

      def init
        @funcs = defs.select{|x| x.is_a?(Defun)}
          .map{|x| [x.name, x]}
          .to_h
        @externs = defs.select{|x| x.is_a?(Extern)}
          .map{|x| [x.name, x]}
          .to_h

        check_duplicated_defun
        check_duplicated_param
        check_misplaced_return(main.stmts)
      end
      attr_reader :funcs, :externs

      def to_ll
        Node.reset

        lines = defs.flat_map{|x| x.to_ll(self)} +
                main.to_ll(self)
        return lines.join("\n") + "\n"
      end

      private

      def check_duplicated_defun
        defuns = defs.select{|x| x.is_a?(Defun)}
        dups = find_duplication(defuns.map(&:name))
        if dups.any?
          raise "duplicated definition of func #{dups.join ','}"
        end
      end

      def check_duplicated_param
        @funcs.each_value do |x|
          dups = find_duplication(x.params.map(&:name))
          if dups.any?
            raise "duplicated param name #{dups.join ','} of func #{x.name}"
          end
        end
      end

      # raise if there is a `return` in main
      def check_misplaced_return(stmts)
        stmts.each do |stmt|
          case stmt
          when If
            check_misplaced_return(stmt.then_stmts)
            check_misplaced_return(stmt.else_stmts)
          when For
            check_misplaced_return(stmt.body_stmts)
          when Return
            raise "cannot return from main"
          end
        end
      end

      # Return duplicated elements in ary
      # Return [] if none
      def find_duplication(ary)
        ct = Hash.new{|h, k| h[k] = 0}
        ary.each do |x|
          ct[x] += 1
        end
        return ct.select{|k, v| v > 1}.map{|k, v| k}
      end
    end

    class Main < Node
      props :stmts

      def to_ll(prog)
        [
          "define i32 @main() {",
          *stmts.map{|x| x.to_ll(prog, [])},
          "  ret i32 0",
          "}",
        ]
      end
    end

    class Defun < Node
      props :name, :params, :body_stmts

      def arity
        params.length
      end

      def param_types
        Array.new(arity, "double")
      end

      def ret_type
        "double"
      end

      def to_ll(prog)
        env = params.map(&:name).to_set
        param_list = params.map{|x| "double %#{x.name}"}.join(", ")

        ll = []
        ll << "define double @#{name}(#{param_list}) {"
        ll.concat body_stmts.flat_map{|x| x.to_ll(prog, env)}
        ll << "  ret double 0.0"
        ll << "}"
        return ll
      end
    end

    class Param < Node
      props :name, :type_name
    end

    class Extern < Node
      props :ret_type, :name, :param_types

      def arity
        param_types.length
      end

      def to_ll(prog)
        [
           "declare #{@ret_type} @#{@name}(#{@param_types.join ','})"
        ]
      end
    end

    class If < Node
      props :cond_expr, :then_stmts, :else_stmts

      def to_ll(prog, env)
        i = newif
        cond_ll, cond_r = @cond_expr.to_ll_r(prog, env)
        then_ll = @then_stmts.flat_map{|x| x.to_ll(prog, env)}
        else_ll = @else_stmts.flat_map{|x| x.to_ll(prog, env)}

        ll = []
        ll.concat cond_ll
        endif = (@else_stmts.any? ? "%Else#{i}" : "%EndIf#{i}")
        ll << "  br i1 #{cond_r}, label %Then#{i}, label #{endif}"
        ll << "Then#{i}:"
        ll.concat then_ll
        ll << "  br label %EndIf#{i}"
        if @else_stmts.any?
          ll << "Else#{i}:"
          ll.concat else_ll  # fallthrough
          ll << "  br label %EndIf#{i}"
        end
        ll << "EndIf#{i}:"
        return ll
      end
    end

    class For < Node
      props :varname, :begin_expr, :end_expr, :step_expr, :body_stmts

      def to_ll(prog, env)
        begin_ll, begin_r = begin_expr.to_ll_r(prog, env)
        end_ll, end_r = end_expr.to_ll_r(prog, env)
        step_ll, step_r = step_expr.to_ll_r(prog, env)
        body_ll = body_stmts.flat_map{|x| x.to_ll(prog, env + [varname])}

        i = newfor
        ll = []
        ll << "  br label %For#{i}"
        ll << "For#{i}:"
        ll.concat begin_ll
        ll.concat end_ll
        ll.concat step_ll
        ll << "  br label %Loop#{i}"

        ll << "Loop#{i}:"
        ll << "  %#{varname} = phi double [#{begin_r}, %For#{i}], [%fori#{i}, %ForInc#{i}]"
        ll << "  %forc#{i} = fcmp oge double %#{varname}, #{end_r}"
        ll << "  br i1 %forc#{i}, label %EndFor#{i}, label %ForBody#{i}"

        ll << "ForBody#{i}:"
        ll.concat body_ll
        ll << "  br label %ForInc#{i}"

        ll << "ForInc#{i}:"
        ll << "  %fori#{i} = fadd double %#{varname}, #{step_r}"
        ll << "  br label %Loop#{i}"

        ll << "EndFor#{i}:"
        return ll
      end
    end

    class Return < Node
      props :expr

      def to_ll(prog, env)
        expr_ll, expr_r = expr.to_ll_r(prog, env)

        ll = []
        ll.concat expr_ll
        ll << "  ret double #{expr_r}"
        return ll
      end
    end

    class ExprStmt < Node
      props :expr

      def to_ll(prog, env)
        ll, r = @expr.to_ll_r(prog, env)
        return ll
      end
    end

    BINOPS = {
      "+" => "fadd double",
      "-" => "fsub double",
      "*" => "fmul double",
      "/" => "fdiv double",
      "%" => "frem double",

      "==" => "fcmp oeq double",
      ">" => "fcmp ogt double",
      ">=" => "fcmp oge double",
      "<" => "fcmp olt double",
      "<=" => "fcmp ole double",
      "!=" => "fcmp one double",

      "&&" => "and i1",
      "||" => "or i1",
    }
    class BinExpr < Node
      props :op, :left_expr, :right_expr

      def to_ll_r(prog, env)
        ll1, r1 = @left_expr.to_ll_r(prog, env)
        ll2, r2 = @right_expr.to_ll_r(prog, env)
        ope = BINOPS[@op] or raise "op #{@op} not implemented yet"

        ll = ll1 + ll2
        r3 = newreg
        ll << "  #{r3} = #{ope} #{r1}, #{r2}"
        return ll, r3
      end
    end

    class UnaryExpr < Node
      props :op, :expr

      def to_ll_r(prog, env)
        expr_ll, expr_r = expr.to_ll_r(prog, env)

        r = newreg
        ll = []
        ll.concat expr_ll
        ll << "  #{r} = fsub double 0.0, #{expr_r}"
        return ll, r
      end
    end

    class FunCall < Node
      props :name, :args

      def to_ll_r(prog, env)
        unless (target = prog.externs[@name] || prog.funcs[@name])
          raise "Unkown function: #{@name}"
        end
        unless target.arity == @args.length
          raise "Invalid number of arguments (#{@name})"
        end

        ll = []
        args_and_types = []
        @args.map{|x| x.to_ll_r(prog, env)}.each.with_index do |(arg_ll, arg_r), i|
          type = target.param_types[i]
          ll.concat(arg_ll)
          case type
          when "i32"
            rr = newreg
            ll << "  #{rr} = fptosi double #{arg_r} to i32"
            args_and_types << "i32 #{rr}"
          when "double"
            args_and_types << "double #{arg_r}"
          else
            raise "type #{type} is not supported"
          end
        end

        r = newreg
        ll << "  #{r} = call #{target.ret_type} @#{name}(#{args_and_types.join(', ')})"
        case target.ret_type
        when "i32"
          rr = newreg
          ll << "  #{rr} = sitofp i32 #{r} to double"
          return ll, rr
        when "double"
          return ll, r
        else
          raise "type #{type} is not supported"
        end
      end
    end

    class VarRef < Node
      props :name

      def to_ll_r(prog, env)
        if !env.include?(name)
          raise "undefined variable #{name}"
        end
        return [], "%#{name}"
      end
    end

    class Literal < Node
      props :value

      def to_ll_r(prog, env)
        case @value
        when Float
          return [], @value.to_s
        when Integer
          return [], "#{@value}.0"
        else
          raise
        end
      end
    end
  end
end
