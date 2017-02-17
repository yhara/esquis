require 'set'

module Esquis
  class Ast
    class DuplicatedDefinition < StandardError; end
    class DuplicatedParamName < StandardError; end
    class MisplacedReturn < StandardError; end

    class Node
      extend Props

      attr_reader :ty  # Instance of Ast::Type

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
      # def to_ll
      # end

      # Return LLVM bitcode as [String] and the name of the register
      # which contains the value of this node
      # def to_ll_r
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
          *defs.flat_map{|x| x.to_ll},
          *main.to_ll
        ]
      end

      def check_duplicated_defun
        names = defs.select{|x| x.is_a?(Defun) || x.is_a?(Extern)}
                    .map(&:name)
        if (dups = Node.find_duplication(names)).any?
          raise DuplicatedDefinition,
            "duplicated definition of func #{dups.join ', '}"
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

      def to_ll
        [
          "define i32 @main() {",
          "  call void @GC_init()",
          *stmts.map{|x| x.to_ll},
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
      props :name, :defmethods
      @@class_id = 0

      def init
        @class_id = (@@class_id += 1)
      end

      def add_type!(env)
        @ty ||= begin
          defmethods.each{|x| x.add_type!(env, self)}
          TyRaw[name]
        end
      end

      def to_ll
        t = %Q{"#{name}"}
        n = %Q{"#{name}.new"}
        [
          "%#{t} = type { i32 }",
          "define %#{t}* @#{n}() {",
          "  %size = ptrtoint %#{t}* getelementptr (%#{t}, %#{t}* null, i32 1) to i64",
          "  %raw_addr = call i8* @GC_malloc(i64 %size)",
          "  %addr = bitcast i8* %raw_addr to %#{t}*",
          "",
          "  call void @llvm.memset.p0i8.i64(i8* %raw_addr, i8 0, i64 %size, i32 4, i1 false)",
          "",
          "  %id_addr = getelementptr inbounds %#{t}, %#{t}* %addr, i32 0, i32 0",
          "  store i32 #{@class_id}, i32* %id_addr",
          "",
          "  ret %#{t}* %addr",
          "}",
          *defmethods.flat_map{|x| x.to_ll}
        ]
      end
    end

    class Defun < Node
      props :name, :params, :ret_type_name, :body_stmts

      def init
        if (dups = Node.find_duplication(params.map(&:name))).any?
          raise DuplicatedParamName,
            "duplicated param name #{dups.join ', '} of func #{name}"
        end
      end

      def add_type!(env)
        @ty ||= begin
          params.each{|x| x.add_type!(env)}

          lvars = params.map{|x| [x.name, x.ty]}.to_h
          newenv = env.add_local_vars(lvars)
          body_stmts.each{|x| x.add_type!(newenv)}

          TyMethod.new(name, params.map(&:ty), TyRaw[ret_type_name])
        end
      end

      def to_ll(funname: name, self_param: nil)
        param_list = params.flat_map(&:to_ll)
        param_list.unshift(self_param) if self_param

        ret_t = @ty.ret_ty.llvm_type
        zero = case ret_t
               when "double" then "0.0"
               when "i32" then "0"
               else raise "type #{ret_type_name} not supported"
               end
        ll = []
        ll << "define #{ret_t} @#{funname}(#{param_list.join ', '}) {"
        ll.concat body_stmts.flat_map{|x| x.to_ll}
        ll << "  ret #{ret_t} #{zero}"
        ll << "}"
        return ll
      end
    end

    class DefMethod < Defun
      def add_type!(env, cls)
        @ty ||= begin
          @cls = cls
          super(env)
        end
      end

      def to_ll
        return super(funname: %Q{"#{@cls.name}##{name}"},
                     self_param: %Q{%"#{@cls.name}"* self})
      end
    end

    class Param < Node
      props :name, :type_name

      def add_type!(env)
        @ty ||= begin
          TyRaw[type_name]
        end
      end

      def to_ll
        return ["#{@ty.llvm_type} %#{name}"]
      end
    end

    class Extern < Node
      props :ret_type_name, :name, :param_type_names

      def add_type!(env)
        @ty ||= begin
          param_tys = param_type_names.map{|x| TyRaw[x]}
          TyMethod.new(name, param_tys, TyRaw[ret_type_name])
        end
      end

      def to_ll
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

      def to_ll
        i = newif
        cond_ll, cond_r = @cond_expr.to_ll_r
        then_ll = @then_stmts.flat_map{|x| x.to_ll}
        else_ll = @else_stmts.flat_map{|x| x.to_ll}

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

      def to_ll
        begin_ll, begin_r = begin_expr.to_ll_r
        end_ll, end_r = end_expr.to_ll_r
        step_ll, step_r = step_expr.to_ll_r
        body_ll = body_stmts.flat_map{|x| x.to_ll}

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

      def to_ll
        expr_ll, expr_r = expr.to_ll_r

        ll = []
        ll.concat expr_ll
        ll << "  ret #{expr.ty.llvm_type} #{expr_r}"
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

      def to_ll
        ll, r = @expr.to_ll_r
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

      def to_ll_r
        ll1, r1 = @left_expr.to_ll_r
        ll2, r2 = @right_expr.to_ll_r
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

      def to_ll_r
        expr_ll, expr_r = expr.to_ll_r

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

      def to_ll_r
        TODO
      end
    end

    class FunCall < Node
      props :name, :args

      def add_type!(env)
        @ty ||= begin
          args.each{|x| x.add_type!(env)}
          unless (@func = env.find_toplevel_func(name))
            raise "undefined function: #{name.inspect}"
          end
          # TODO: check arity and arg types
          @func.ty.ret_ty
        end
      end

      def to_ll_r
        ll = []
        args_and_types = []
        @args.map{|x| x.to_ll_r}.each.with_index do |(arg_ll, arg_r), i|
          type = @func.ty.param_tys[i]
          ll.concat(arg_ll)
          case type
          when TyRaw["Int"], TyRaw["i32"]
            rr = newreg
            ll << "  #{rr} = fptosi double #{arg_r} to i32"
            args_and_types << "i32 #{rr}"
          when TyRaw["Float"], TyRaw["double"]
            args_and_types << "double #{arg_r}"
          else
            raise "type #{type} is not supported"
          end
        end

        ret_type_name = case @func.ty.ret_ty
                        when TyRaw["Int"], TyRaw["i32"] then "i32"
                        when TyRaw["Float"], TyRaw["double"] then "double"
                        else raise "type #{type} is not supported"
                        end
        r = newreg
        ll << "  #{r} = call #{ret_type_name} @#{name}(#{args_and_types.join(', ')})"
        case ret_type_name
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

      def to_ll_r
        return [], "%#{name}"
      end
    end

    class Literal < Node
      props :value

      def add_type!(env)
        @ty ||= begin
          case @value
          when Float then TyRaw["Float"]
          when Integer then TyRaw["Int"]
          else raise
          end
        end
      end

      def to_ll_r
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

      attr_writer :llvm_type
      def llvm_type
        @llvm_type or raise "Cannot convert #{self} to llvm"
      end

      def inspect
        "#<TyRaw #{name}>"
      end
      alias to_s inspect
    end

    TyRaw["Float"].llvm_type = "double"
    TyRaw["double"].llvm_type = "double"
    TyRaw["Int"].llvm_type = "i32"
    TyRaw["i32"].llvm_type = "i32"

    class TyMethod < Type
      def initialize(name, param_tys, ret_ty)
        @name, @param_tys, @ret_ty = name, param_tys, ret_ty
      end
      attr_reader :name, :param_tys, :ret_ty
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
