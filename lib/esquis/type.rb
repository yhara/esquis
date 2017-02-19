module Esquis
  module Type
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

      def inspect
        "#<TyRaw #{name}>"
      end
      alias to_s inspect
    end

    TyRaw["Float"].llvm_type = "double"
    TyRaw["double"].llvm_type = "double"
    TyRaw["Int"].llvm_type = "i32"
    TyRaw["i32"].llvm_type = "i32"

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
