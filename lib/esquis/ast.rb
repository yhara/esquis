require 'set'
require 'esquis/type'

module Esquis
  module Ast
    include Esquis::Type

    # for unit tests
    def self.reset
      Node.reset
      DefClass.reset
    end

    class DuplicatedDefinition < StandardError; end
    class DuplicatedParamName < StandardError; end
    class MisplacedReturn < StandardError; end
    class TypeMismatch < StandardError; end
    class ArityMismatch < StandardError; end

    class Node
      include Esquis::Type
      extend Props

      attr_reader :ty  # Instance of Esquis::Type

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
        check_duplicated_defun
        check_duplicated_defclass
      end

      # Return LLVM bitcode as String
      # without_header: for testing
      def to_ll_str(without_header: false)
        Node.reset

        env = Env.new
        Esquis::Stdlib::TOPLEVEL_FUNCS.each do |k, v|
          env = env.add_toplevel_func(k, v)
        end
        add_type!(env)

        header = (without_header ? "" : Stdlib::LL_STDLIB + LL_HEADER)
        return header + to_ll.join("\n") + "\n"
      end
      LL_HEADER = <<~EOD
        declare void @GC_init()
        declare i8* @GC_malloc(i64)
        declare void @llvm.memset.p0i8.i64(i8* nocapture, i8, i64, i32, i1)
      EOD

      private

      def add_type!(env)
        @ty ||= begin
          newenv = env
          defs.each do |x|
            case x
            when DefClass
              newenv = newenv.add_class(x.name, x)
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

      def check_duplicated_defclass
        names = defs.select{|x| x.is_a?(DefClass)}.map(&:name)
        if (dups = Node.find_duplication(names)).any?
          raise DuplicatedDefinition,
            "duplicated definition of class #{dups.join ', '}"
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
          *stmts.flat_map{|x| x.to_ll},
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

      def self.reset; @@class_id = 0; end
      reset

      def init
        @class_id = (@@class_id += 1)
        @instance_ty = TyRaw[name]

        @initialize = defmethods.find{|x| x.is_a?(DefInitialize)}
        if @initialize.nil?
          @initialize = DefInitialize.new([], [])
          @defmethods << @initialize
        end
        @ivars = @initialize.ivars

        @new = DefMethod.new("new", @initialize.params, @name, [])
        @class_methods = {"new" => @new}

        getters = @ivars.map{|ivar|
          n = ivar.name.sub("@", "")
          [n,
           DefMethod.new(n, [], ivar.type_name, 
             [Return.new(VarRef.new(ivar.name))])
          ]
        }.to_h
        @instance_methods = 
          getters.merge(defmethods.map{|x| [x.name, x]}.to_h)
      end
      attr_reader :instance_ty, :ivars, :class_methods, :instance_methods

      def full_name
        name
      end

      def add_type!(env)
        @ty ||= begin
          # Note: we must run add_type! on @ivars before @new,
          # because the former has an extra parameter(idx) :-(
          idx = 0
          @ivars.each do |x|
            if x.name[0] == "@"
              x.add_type!(env, (idx += 1))
            else
              x.add_type!(env)
            end
          end

          @new.add_type!(env, self)

          newenv = env.set_selfcls(self)
          @instance_methods.each_value{|x| x.add_type!(newenv, self)}
          TyRaw["Class"]
        end
      end

      def to_ll
        t = %Q{"#{name}"}
        func_new = %Q{"#{name}.new"}
        func_initialize = %Q{"#{name}#initialize"}
        new_args = @ivars.map{|x|
          %Q{#{x.ty.llvm_type} %"#{x.name}"}
        }
        init_args = ["%#{t}* %addr"] + new_args
        struct_members = ["i32"] + @ivars.map{|x| x.ty.llvm_type}
        [
          "%#{t} = type { #{struct_members.join ', '} }",
          "define %#{t}* @#{func_new}(#{new_args.join ', '}) {",
          "  %size = ptrtoint %#{t}* getelementptr (%#{t}, %#{t}* null, i32 1) to i64",
          "  %raw_addr = call i8* @GC_malloc(i64 %size)",
          "  %addr = bitcast i8* %raw_addr to %#{t}*",
          "",
          "  call void @llvm.memset.p0i8.i64(i8* %raw_addr, i8 0, i64 %size, i32 4, i1 false)",
          "",
          "  %id_addr = getelementptr inbounds %#{t}, %#{t}* %addr, i32 0, i32 0",
          "  store i32 #{@class_id}, i32* %id_addr",
          "  call void @#{func_initialize}(#{init_args.join ', '})",
          "  ret %#{t}* %addr",
          "}",
          *@instance_methods.values.flat_map{|x| x.to_ll}
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

      def arity
        params.length
      end

      def add_type!(env)
        return @ty if @ty

        params.each{|x| x.add_type!(env)}
        @ty = TyMethod.new(name, params.map(&:ty), TyRaw[ret_type_name])

        lvars = params.map{|x| [x.name, x.ty]}.to_h
        newenv = env.add_local_vars(lvars)
        body_stmts.each{|x| x.add_type!(newenv)}

        last_ty = (body_stmts.empty? ? TyRaw["Void"] : body_stmts.last.ty)
        if last_ty != @ty.ret_ty &&
           name != "new" && ret_type_name != "Void" && !manual_return?
          raise TypeMismatch, "#{name} is decalred to return #{ret_type_name}"+
            " but returns #{body_stmts.last.ty.inspect}"
        end

        @ty
      end

      def to_ll(funname: name, self_param: nil, init_ll: nil)
        param_list = params.flat_map(&:to_ll)
        param_list.unshift(self_param) if self_param

        ret_t = @ty.ret_ty.llvm_type
        ll = []
        ll << "define #{ret_t} @#{funname}(#{param_list.join ', '}) {"
        ll.concat init_ll if init_ll
        if ret_t == "void"
          ll.concat body_stmts.flat_map(&:to_ll)
          ll << "  ret void"
        elsif manual_return?
          ll.concat body_stmts.flat_map(&:to_ll)
        else
          *stmts, last_stmt = body_stmts
          raise "unexpected" unless last_stmt.is_a?(ExprStmt)
          ll.concat stmts.flat_map(&:to_ll)
          last_ll, last_r = last_stmt.expr.to_ll_r
          ll.concat last_ll
          ll << "  ret #{ret_t} #{last_r}"
        end
        ll << "}"
        return ll
      end

      def inspect
        "#<Defun #{@name}(#{@params})>"
      end

      private

      def manual_return?(stmts = body_stmts)
        last_stmt = stmts.last
        case last_stmt
        when Ast::Return then true
        when Ast::If
          return false if !manual_return?(last_stmt.then_stmts) 
          if last_stmt.else_stmts.any?
            manual_return?(last_stmt.else_stmts) 
          else
            true
          end
        else
          false
        end
      end
    end

    class DefMethod < Defun
      def add_type!(env, cls)
        @ty ||= begin
          @cls = cls
          super(env)
        end
      end

      def full_name
        @cls.full_name + "#" + name
      end

      def to_ll(init_ll: nil)
        return super(funname: %Q{"#{@cls.name}##{name}"},
                     self_param: %Q{%"#{@cls.name}"* %self},
                     init_ll: init_ll)
      end
    end

    class DefInitialize < DefMethod
      props :params, :body_stmts

      def name; "initialize"; end
      def ret_type_name; "Void"; end

      def ivars
        params.select{|x| x.name.start_with?("@")}
      end

      def to_ll
        t = %Q{"#{@cls.name}"}
        init_ivars = ivars.flat_map.with_index(1){|ivar, i|
          n = %Q{"#{ivar.name}"}
          it = ivar.ty.llvm_type
          [
            "  %ivar#{i}_addr = getelementptr inbounds %#{t}, %#{t}* %self, i32 0, i32 #{i}",
            "  store #{it} %#{n}, #{it}* %ivar#{i}_addr",
          ]
        } + [""]
        return super(init_ll: init_ivars)
      end
    end

    class Param < Node
      props :name, :type_name
      attr_reader :idx  # used for ivar

      def add_type!(env, idx=nil)
        @ty ||= begin
          @idx = idx if idx
          TyRaw[type_name]
        end
      end

      def to_ll
        if name[0] == "@"
          return [%Q{#{@ty.llvm_type} %"#{name}"}]
        else
          return ["#{@ty.llvm_type} %#{name}"]
        end
      end

      def inspect
        if @idx
          "#<Param #{type_name} #{name}(#{@idx})>"
        else
          "#<Param #{type_name} #{name}>"
        end
      end
    end

    class Extern < Node
      props :ret_type_name, :name, :params

      def arity
        params.length
      end

      def add_type!(env)
        @ty ||= begin
          params.each{|x| x.add_type!(env)}
          TyMethod.new(name, params.map(&:ty), TyRaw[ret_type_name])
        end
      end

      def to_ll
        param_types = params.map{|x| x.ty.llvm_type}
        [
           "declare #{@ty.ret_ty.llvm_type} @#{@name}(#{param_types.join ','})"
        ]
      end

      def inspect
        "#<Extern #{@name}(#{@params})>"
      end
    end

    class If < Node
      props :cond_expr, :then_stmts, :else_stmts

      def add_type!(env)
        @ty ||= begin
          cond_ty = cond_expr.add_type!(env)
          if cond_ty != TyRaw["Bool"]
            raise TypeMismatch, "condition of if-stmt must be Bool (got #{cond_ty})"
          end

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
      props :varname, :var_type_name,
        :begin_expr, :end_expr, :step_expr, :body_stmts

      def add_type!(env)
        @ty ||= begin
          begin_expr.add_type!(env)
          end_expr.add_type!(env)
          step_expr.add_type!(env)

          newenv = env.add_local_vars(varname => TyRaw[var_type_name])
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
          expr.ty
        end
      end

      def to_ll
        ll, r = @expr.to_ll_r
        return ll
      end
    end

    BINOPS = {
      "+" => [TyRaw["Float"], "fadd double"],
      "-" => [TyRaw["Float"], "fsub double"],
      "*" => [TyRaw["Float"], "fmul double"],
      "/" => [TyRaw["Float"], "fdiv double"],
      "%" => [TyRaw["Float"], "frem double"],

      "==" => [TyRaw["Bool"], "fcmp oeq double"],
      ">"  => [TyRaw["Bool"], "fcmp ogt double"],
      ">=" => [TyRaw["Bool"], "fcmp oge double"],
      "<"  => [TyRaw["Bool"], "fcmp olt double"],
      "<=" => [TyRaw["Bool"], "fcmp ole double"],
      "!=" => [TyRaw["Bool"], "fcmp one double"],

      "&&" => [TyRaw["Bool"], "and i1"],
      "||" => [TyRaw["Bool"], "or i1"],
    }
    class BinExpr < Node
      props :op, :left_expr, :right_expr

      def add_type!(env)
        @ty ||= begin
          left_expr.add_type!(env)
          right_expr.add_type!(env)

          ty, _ = BINOPS[@op]
          raise "operator not implemented: #{@op}" unless ty
          ty
        end
      end

      def to_ll_r
        ll1, r1 = @left_expr.to_ll_r
        ll2, r2 = @right_expr.to_ll_r
        ope = BINOPS[@op][1]

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

    class FunCall < Node
      props :name, :args

      def add_type!(env)
        @ty ||= begin
          args.each{|x| x.add_type!(env)}
          unless (@func = env.find_toplevel_func(name))
            raise "undefined function: #{name.inspect}"
          end
          if args.length != @func.arity
            raise ArityMismatch,
              "#{name} takes #{@func.arity} args but got #{args.length} args"
          end
          @func.params.zip(args) do |param, arg|
            if !Esquis::Type.acceptable?(param.ty, arg.ty)
              raise TypeMismatch,
                "parameter #{param.name} of #{name} is #{param.ty}"+
                " but got #{arg.ty}"
            end
          end
          @func.ty.ret_ty
        end
      end

      def to_ll_r(funname: name, funmeth: @func, self_ty: nil, arg_exprs: @args)
        ll = []
        args_and_types = []
        param_tys = funmeth.ty.param_tys
        param_tys.unshift(self_ty) if self_ty
        arg_exprs.map{|x| x.to_ll_r}.each.with_index do |(arg_ll, arg_r), i|
          type = param_tys[i]
          ll.concat(arg_ll)
          case type
          when TyRaw["Int"], TyRaw["i32"]
            rr = newreg
            ll << "  #{rr} = fptosi double #{arg_r} to i32"
            args_and_types << "i32 #{rr}"
          else
            args_and_types << "#{type.llvm_type} #{arg_r}"
          end
        end

        ret_type_name = funmeth.ty.ret_ty.llvm_type
        r = newreg
        if ret_type_name == "void"
          ll << "  call #{ret_type_name} @#{funname}(#{args_and_types.join(', ')})"
        else
          ll << "  #{r} = call #{ret_type_name} @#{funname}(#{args_and_types.join(', ')})"
        end
        case ret_type_name
        when "i32"
          rr = newreg
          ll << "  #{rr} = sitofp i32 #{r} to double"
          return ll, rr
        when "double", /%(.*)\*/
          return ll, r
        when "void"
          return ll, nil
        else
          raise "type #{ret_type_name} is not supported as a return value"
        end
      end
    end

    class MethodCall < FunCall
      props :receiver_expr, :method_name, :args

      def add_type!(env)
        @ty ||= begin
          receiver_ty = receiver_expr.add_type!(env)
          if receiver_ty == TyRaw["Class"]
            # Class method call (only .new is currently supported)
            @method = env.fetch_class_method(receiver_expr.name, "new")
          else
            @method = env.fetch_instance_method(receiver_ty, method_name)
          end
          args.each{|x| x.add_type!(env)}

          if args.length != @method.arity
            raise ArityMismatch,
              "#{@method.full_name} takes #{@method.arity} args but got #{args.length} args"
          end
          @method.params.zip(args) do |param, arg|
            if param.ty != arg.ty
              raise TypeMismatch,
                "parameter #{param.name} of #{@method.full_name} "+
                "is #{param.ty} but got #{arg.ty.inspect}"
            end
          end
          @method.ty.ret_ty
        end
      end

      def to_ll_r
        ll = []
        if receiver_expr.ty == TyRaw["Class"]
          m = %Q{"#{receiver_expr.name}.#{method_name}"}
          call_ll, call_r = super(funname: m, funmeth: @method, arg_exprs: args)
        else
          m = %Q{"#{receiver_expr.ty.name}##{method_name}"}
          call_ll, call_r = super(funname: m, funmeth: @method,
                                  self_ty: receiver_expr.ty,
                                  arg_exprs: [receiver_expr] + args)
        end
        ll.concat call_ll
        return ll, call_r
      end
    end

    class VarRef < Node
      props :name

      def add_type!(env)
        @ty ||= begin
          if (ty = env.find_local_var(name))
            ty
          elsif (@ivar = env.find_instance_var(name))
            @selfcls = env.selfcls
            @ivar.ty
          elsif (cls = env.find_class(name))
            TyRaw["Class"]
          else
            raise "undefined variable: #{name}"
          end
        end
      end

      def to_ll_r
        if name[0] == "@"
          r1, r2 = newreg, newreg
          t = %Q{"#{@selfcls.full_name}"}
          ll = [
            "  #{r1} = getelementptr inbounds %#{t}, %#{t}* %self, i32 0, i32 #{@ivar.idx}",
            "  #{r2} = load #{@ty.llvm_type}, #{@ty.llvm_type}* #{r1}",
          ]
          return ll, r2
        else
          return [], "%#{name}"
        end
      end

      def inspect
        "#<VarRef #{name}>"
      end
    end

    class Literal < Node
      props :value

      def add_type!(env)
        @ty ||= begin
          case @value
          when Float then TyRaw["Float"]
          when Integer 
            # Currently, all numbers in Esquis are treated as Float
            TyRaw["Float"]
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

    class Env
      def initialize(toplevel_funcs = {}, local_vars = {},
                     classes = {}, selfcls = nil)
        @toplevel_funcs, @local_vars, @classes, @selfcls =
          toplevel_funcs, local_vars, classes, selfcls
      end

      def selfcls
        @selfcls or raise "self not set"
      end

      def merge(toplevel_funcs: @toplevel_funcs, local_vars: @local_vars,
                classes: @classes, selfcls: @selfcls)
        return Env.new(toplevel_funcs, local_vars, classes, selfcls)
      end

      # @param lvars [{String => Ty}]
      def add_local_vars(lvars)
        return merge(local_vars: @local_vars.merge(lvars))
      end

      def find_local_var(name)
        return @local_vars[name]
      end

      def set_selfcls(cls)
        raise "self already set to #{@selfcls.inspect}" if @selfcls
        return merge(selfcls: cls)
      end

      # Find ivar (Return nil outside a class)
      def find_instance_var(name)
        return @selfcls && @selfcls.ivars.find{|x| x.name == name}
      end

      # @param name [String]
      # @param defun [Ast::Defun]
      # @return [Env]
      def add_toplevel_func(name, defun)
        raise if @toplevel_funcs.key?(name)
        return merge(toplevel_funcs: @toplevel_funcs.merge(name => defun))
      end

      # @return [Ast::Defun or nil]
      def find_toplevel_func(name)
        @toplevel_funcs[name]
      end

      def add_class(name, ty)
        return merge(classes: @classes.merge(name => ty))
      end

      def find_class(name)
        @classes[name]
      end

      def fetch_class(name)
        @classes[name] or raise "Undefined class #{name}"
      end

      # @return [DefMethod] 
      def fetch_instance_method(receiver_ty, method_name)
        cls = fetch_class(receiver_ty.name)
        return cls.instance_methods.fetch(method_name)
      end

      # @return [DefMethod] 
      def fetch_class_method(cls_name, method_name)
        cls = fetch_class(cls_name)
        return cls.class_methods.fetch(method_name)
      end
    end
  end
end
