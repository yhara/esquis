module Esquis
  module Props
    def props(*names)
      define_method "initialize" do |*args|
        if names.length != args.length
          raise ArgumentError,
            "wrong number of arguments (given #{args.length}, expected #{names.length})"
        end
        names.zip(args).each do |name, arg|
          instance_variable_set("@#{name}", arg)
        end
        init
      end
      attr_reader *names

      define_method "init", proc{}
      private "init"
    end
  end
end
