require 'active_record'

module ActiveRecord
  module ConnectionAdapters

    class TableDefinition
      def uuid(*args)
        opts = args.extract_options!
        column_names = args
        type, default_opts  = @base.uuid

        # prefer the values provided by the user...
        options = default_opts.merge!(opts)

        column_names.each { |name| column(name, type, options) }
      end
    end

  end
end
