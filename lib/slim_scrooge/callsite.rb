# Author: Stephen Sykes

module SlimScrooge
  class Callsite
    ScroogeComma = ",".freeze 
    ScroogeRegexJoin = /(?:LEFT|INNER|OUTER|CROSS)*\s*(?:STRAIGHT_JOIN|JOIN)/i

    attr_accessor :seen_columns
    attr_reader :columns_hash, :primary_key, :model_class

    class << self
      def make_callsite(model_class, original_sql)
        if use_scrooge?(model_class, original_sql)
          new(model_class)
        else
          nil
        end
      end

      def use_scrooge?(model_class, original_sql)
        original_sql =~ select_regexp(model_class.table_name) && 
        model_class.columns_hash.has_key?(model_class.primary_key) && 
        original_sql !~ ScroogeRegexJoin
      end
      
      def select_regexp(table_name)
        %r{SELECT (`?(?:#{table_name})?`?.?\\*) FROM}
      end
    end

    def initialize(model_class)
      @all_columns = SimpleSet.new(model_class.column_names)
      @model_class = model_class
      @quoted_table_name = model_class.quoted_table_name
      @primary_key = model_class.primary_key
      @columns_hash = model_class.columns_hash
      @select_regexp = self.class.select_regexp(model_class.table_name)
      @seen_columns = SimpleSet.new(essential_columns)
    end

    def essential_columns
      @model_class.reflect_on_all_associations.inject([@model_class.primary_key]) do |arr, assoc|
        if assoc.options[:dependent] && assoc.macro == :belongs_to
          arr << assoc.association_foreign_key
        end
        arr
      end
    end

    def scrooged_sql(seen_columns, sql)
      sql.gsub(@select_regexp, "SELECT #{scrooge_select_sql(seen_columns)} FROM")
    end
    
    def missing_columns(fetched_columns)
      (@all_columns - SimpleSet.new(fetched_columns)) << @primary_key
    end
    
    def reload_sql(primary_keys, fetched_columns)
      sql_keys = primary_keys.collect{|pk| "'#{pk}'"}.join(ScroogeComma)
      cols = scrooge_select_sql(missing_columns(fetched_columns))
      "SELECT #{cols} FROM #{@quoted_table_name} WHERE #{@quoted_table_name}.#{@primary_key} IN (#{sql_keys})"
    end

    def scrooge_select_sql(set)
      set.collect do |name|
        "#{@quoted_table_name}.#{@model_class.connection.quote_column_name(name)}"
      end.join(ScroogeComma)
    end
  end
end
