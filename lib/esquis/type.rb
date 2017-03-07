module Esquis
  module Type
    # Returns it is allowed to pass a value of arg_ty as a parameter of 
    # param_ty. Needed for current (ad-hoc) numeric type coersion rule.
    def self.acceptable?(param_ty, arg_ty)
      if compatible?(param_ty, arg_ty)
        true
      elsif param_ty == TyRaw["i32"] && arg_ty == TyRaw["Float"]
        # Will be coersed with fptosi (see Ast::FunCall#to_ll_r)
        true
      else
        false
      end
    end

    def self.compatible?(param_ty, arg_ty)
      return param_ty == arg_ty ||
             param_ty.llvm_type == arg_ty.llvm_type
    end

    class Base
    end

    class TyRaw < Base
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
        @llvm_type || %Q{%"#{name}"*}
      end

      attr_writer :llvm_zero
      def llvm_zero
        @llvm_zero || "null"
      end

      def inspect
        "#<TyRaw #{name}>"
      end
      alias to_s inspect
    end

    TyRaw["Float"].llvm_type = "double"
    TyRaw["Float"].llvm_zero = "0.0"
    TyRaw["double"].llvm_type = "double"
    TyRaw["double"].llvm_zero = "0.0"
    TyRaw["Int"].llvm_type = "i32"
    TyRaw["Int"].llvm_zero = "0"
    TyRaw["i32"].llvm_type = "i32"
    TyRaw["Int"].llvm_zero = "0"
    TyRaw["Bool"].llvm_type = "i1"
    TyRaw["Bool"].llvm_zero = "0"
    TyRaw["Void"].llvm_type = "void"

    class TyMethod < Base
      def initialize(name, param_tys, ret_ty)
        @name, @param_tys, @ret_ty = name, param_tys, ret_ty
      end
      attr_reader :name, :param_tys, :ret_ty
    end

    # Indicates this node has no type (eg. return statement)
    class NoType < Base
    end
  end
end
