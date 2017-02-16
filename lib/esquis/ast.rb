require 'set'

module Esquis
  class Ast
    class DuplicatedDefinition < StandardError; end
    class DuplicatedParamName < StandardError; end
    class MisplacedReturn < StandardError; end

    class Node
      extend Props

      # Return duplicated elements in ary
      # Return [] if none
      def self.find_duplication(ary)
        ct = Hash.new{|h, k| h[k] = 0}
        ary.each do |x|
          ct[x] += 1
        end
        return ct.select{|k, v| v > 1}.map{|k, v| k}
      end

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

      # Return LLVM bitcode as [String]
      # @param prog [Program]
      # @param env [Set]
      # def to_ll(prog, env)
      # end

      # Return LLVM bitcode as [String] and the name of the register
      # which contains the value of this node
      # def to_ll_r(prog, env)
      # end

      # @param env[Hash<String, Type>]
      # def add_type!(env)
      # end
    end

    # The whole program
    # Consists of definitions(defs) and the rest(main)
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
      end
      attr_reader :funcs, :externs

      # Return LLVM bitcode as String
      # without_header: for testing
      def to_ll_str(without_header: false)
        Node.reset

        add_type!(Env.new)

        header = (without_header ? [] : LL_HEADER)
        return (header + to_ll).join("\n") + "\n"
      end
      LL_HEADER = [
        "declare void @GC_init()",
        "declare i8* @GC_malloc(i64)",
        "declare void @llvm.memset.p0i8.i64(i8* nocapture, i8, i64, i32, i1)",
      ]

      private

      def add_type!(env)
        @ty ||= begin
          newenv = env
          defs.each do |x|
            case x
            when DefClass
              # TODO
            when Defun, Extern
              newenv = newenv.add_toplevel_func(x.name, x)
            end
          end

          defs.each{|x| x.add_type!(newenv) }
          main.add_type!(newenv)
          NoType
        end
      end

      def to_ll
        [
          *defs.flat_map{|x| x.to_ll(self)},
          *main.to_ll(self)
        ]
      end

      def check_duplicated_defun
        names = defs.select{|x| x.is_a?(Defun) || x.is_a?(Extern)}
                    .map(&:name)
        if (dups = Node.find_duplication(names)).any?
          raise DuplicatedDefinition,
            "duplicated definition of func #{dups.join ','}"
        end
      end
    end

    # Statements written in the toplevel
    class Main < Node
      props :stmts

      def init
        check_misplaced_return(stmts)
      end

      def add_type!(env)
        @ty ||= begin
          stmts.each{|x| x.add_type!(env)}
          NoType
        end
      end

      def to_ll(prog)
        [
          "define i32 @main() {",
          "  call void @GC_init()",
          *stmts.map{|x| x.to_ll(prog, [])},
          "  ret i32 0",
          "}",
        ]
      end
      
      private

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
            raise MisplacedReturn, "cannot return from main"
          end
        end
      end
    end

    class DefClass < Node
      props :name, :defuns

      def add_type!(env)
        @ty ||= begin
          defuns.each{|x| x.add_type!(env)}
          TyRaw[name]
        end
      end

      def to_ll(prog)
        [
          "%\"#{name}\" = type { i32 }"
        ]
      end
    end

    class Defun < Node
      props :name, :params, :ret_type_name, :body_stmts
      attr_reader :ret_ty

      def init
        if (dups = Node.find_duplication(params.map(&:name))).any?
          raise DuplicatedParamName,
            "duplicated param name #{dups.join ','} of func #{name}"
        end
      end

      def arity
        params.length
      end

      def param_type_names
        Array.new(arity, "double")
      end

      def ret_type_name
        "double"
      end

      def add_type!(env)
        @ty ||= begin
          lvars = params.map{|x| [x.name, TyRaw[x.type_name]]}.to_h
          newenv = env.add_local_vars(lvars)

          body_stmts.each{|x| x.add_type!(newenv)}
          param_tys = Array.new(arity, TyRaw["Float"])
          @ret_ty = TyRaw["Float"]
          TyMethod.new(name, param_tys)
        end
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
      props :ret_type_name, :name, :param_type_names
      attr_reader :ret_ty

      def add_type!(env)
        @ty ||= begin
          param_tys = param_type_names.map{|x| TyRaw[x]}
          @ret_ty = TyRaw[ret_type_name]
          TyMethod.new(name, param_tys)
        end
      end

      def arity
        param_type_names.length
      end

      def to_ll(prog)
        [
           "declare #{@ret_type_name} @#{@name}(#{@param_type_names.join ','})"
        ]
      end
    end

    class If < Node
      props :cond_expr, :then_stmts, :else_stmts

      def add_type!(env)
        @ty ||= begin
          cond_expr.add_type!(env)
          then_stmts.each{|x| x.add_type!(env)}
          else_stmts.each{|x| x.add_type!(env)}
        end
      end

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

      def add_type!(env)
        @ty ||= begin
          begin_expr.add_type!(env)
          end_expr.add_type!(env)
          step_expr.add_type!(env)

          newenv = env.add_local_vars(varname => TyRaw["Float"])
          body_stmts.each{|x| x.add_type!(newenv)}
          NoType
        end
      end

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

      def add_type!(env)
        @ty ||= begin
          expr.add_type!(env)
          NoType
        end
      end

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

      def add_type!(env)
        @ty ||= begin
          expr.add_type!(env)
          NoType
        end
      end

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

      def add_type!(env)
        @ty ||= begin
          left_expr.add_type!(env)
          right_expr.add_type!(env)
          TyRaw["Float"]
        end
      end

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

      def add_type!(env)
        @ty ||= begin
          expr.add_type!(env)
          TyRaw["Float"]
        end
      end

      def to_ll_r(prog, env)
        expr_ll, expr_r = expr.to_ll_r(prog, env)

        r = newreg
        ll = []
        ll.concat expr_ll
        ll << "  #{r} = fsub double 0.0, #{expr_r}"
        return ll, r
      end
    end

    class MethodCall < Node
      props :receiver_expr, :method_name, :args

      def add_type!(env)
        @ty ||= begin
          receiver_ty = receiver_expr.add_type!(env)
          method = env.find_method(receiver_ty, method_name)
          # TODO: check arity and arg types
          method.return_ty
        end
      end

      def to_ll_r(prog, env)
        TODO
      end
    end

    class FunCall < Node
      props :name, :args

      def add_type!(env)
        @ty ||= begin
          args.each{|x| x.add_type!(env)}
          if (func = env.find_toplevel_func(name))
            # TODO: check arity and arg types
            func.ret_ty
          else
            raise "undefined function: #{name.inspect}"
          end
        end
      end

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
          type = target.param_type_names[i]
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
        ll << "  #{r} = call #{target.ret_type_name} @#{name}(#{args_and_types.join(', ')})"
        case target.ret_type_name
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

      def add_type!(env)
        @ty ||= begin
          if (ty = env.find_local_var(name))
            ty
          else
            raise "undefined variable: #{name}"
          end
        end
      end

      def to_ll_r(prog, env)
        if !env.include?(name)
          raise "undefined variable #{name}"
        end
        return [], "%#{name}"
      end
    end

    class Literal < Node
      props :value

      def add_type!(env)
        @ty ||= begin
          case @value
          when Float then TyRaw["Float"]
          when Integer then TyRaw["Integer"]
          else raise
          end
        end
      end

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

    #
    # Typing
    #
    class Type
    end

    class TyRaw < Type
      @@types = {}
      def self.[](name)
        @@types[name] ||= new(name)
      end

      def initialize(name)
        @name = name
        @@types[name] = self
      end
      attr_reader :name
    end

    class TyMethod < Type
      def initialize(name, arg_types)
        @name, @arg_types = name, arg_types
      end
    end

    # Indicates this node has no type (eg. return statement)
    class NoType < Type
    end

    class Env
      def initialize(toplevel_funcs = {}, local_vars = {})
        @toplevel_funcs, @local_vars = toplevel_funcs, local_vars
      end

      # @param lvars [{String => Ty}]
      def add_local_vars(lvars)
        return Env.new(@toplevel_funcs,
                       @local_vars.merge(lvars))
      end

      def find_local_var(name)
        return @local_vars[name]
      end

      # @return [Ast::Defun]
      def find_method(receiver_ty, method_name)

      end

      # @param name [String]
      # @param defun [Ast::Defun]
      # @return [Env]
      def add_toplevel_func(name, defun)
        raise if @toplevel_funcs.key?(name)
        return Env.new(@toplevel_funcs.merge(name => defun))
      end

      # @return [Ast::Defun or nil]
      def find_toplevel_func(name)
        @toplevel_funcs[name]
      end
    end
  end
end
