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
          new(model_class, original_sql)
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

    def initialize(model_class, original_sql)
      @all_columns = SimpleSet.new(model_class.column_names)
      @model_class = model_class
      @quoted_table_name = model_class.quoted_table_name
      @primary_key = model_class.primary_key
      @columns_hash = model_class.columns_hash
      @original_sql = original_sql
      @select_regexp = self.class.select_regexp(model_class.table_name)
      association_keys = model_class.reflect_on_all_associations.inject([]) do |arr, assoc|
        if assoc.options[:dependent] == :destroy
          arr << (assoc.options.has_key?(:foreign_key) ? assoc.options[:foreign_key].to_s : assoc.name + "_id")
        end
        arr
      end
      @seen_columns = SimpleSet.new([@primary_key] + association_keys)
    end
    
    def scrooged_sql(seen_columns)
      @original_sql.gsub(@select_regexp, "SELECT #{scrooge_select_sql(seen_columns)} FROM")
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
      set.collect{|a| attribute_with_table(a)}.join(ScroogeComma)
    end

    def attribute_with_table(attr_name)
      "#{@quoted_table_name}.#{attr_name}"
    end
  end
end
