# Author: Stephen Sykes

module SlimScrooge
  module SelectAll
    def self.included(base)
      base.alias_method_chain :select_all, :slim_scrooge
    end

    def select_all_with_slim_scrooge(sql, name = nil)
      callsite_key = SlimScrooge::Callsites.callsite_key(callsite_hash, sql)
      if callsite = SlimScrooge::Callsites.find_or_create(sql, callsite_key, name)
        seen_columns = callsite.seen_columns
        rows = select_all_without_slim_scrooge(callsite.scrooged_sql(seen_columns), name + " SlimScrooged")
        result_set = SlimScrooge::ResultSet.new(rows.dup, callsite_key, seen_columns)
        rows.each do |row|
          row.slim_result_set = result_set
        end
        rows
      else
        select_all_without_slim_scrooge(sql, name)
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::MysqlAdapter.send(:include, SlimScrooge::SelectAll)

class Mysql::Result
  class RowHash
    attr_accessor :slim_result_set

    def slim_attribute_not_in_result_set(attrib_name)
      return nil unless scrooged?
      callsite = SlimScrooge::Callsites[@slim_result_set.callsite_key]
      if callsite.columns_hash.has_key?(attrib_name)
        @slim_result_set.reload!
        self[attrib_name]
      else
        nil
      end
    end
    
    def scrooged?
      @slim_result_set
    end
    
    alias_method :has_key_without_slim_scrooge?, :has_key?

    def has_key?(name)
      has_key_without_slim_scrooge?(name) ||
      scrooged? && SlimScrooge::Callsites[@slim_result_set.callsite_key].columns_hash.has_key?(name)
    end

    alias_method :include?, :has_key?

    alias_method :keys_without_slim_scrooge, :keys
    
    def keys
      scrooged? ? SlimScrooge::Callsites[@slim_result_set.callsite_key].columns_hash.keys : keys_without_slim_scrooge
    end
    
    alias_method :to_hash_without_slim_scrooge, :to_hash
    
    def to_hash
      to_hash_without_slim_scrooge
      @slim_result_set.reload! if scrooged?
      @real_hash
    end
  end
end
