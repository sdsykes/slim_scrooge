# Author: Stephen Sykes

module SlimScrooge
  class ResultSet
    attr_reader :rows, :callsite_key
    
    def initialize(rows, callsite_key, fetched_columns)
      @rows = rows
      @callsite_key = callsite_key
      @fetched_columns = fetched_columns
    end
    
    def rows_by_key(key)
      @rows.inject({}) {|hash, row| hash[row[key]] = row; hash}
    end
    
    def reload!
      callsite = Callsites[@callsite_key]
      rows_hash = rows_by_key(callsite.primary_key)
      sql = callsite.reload_sql(rows_hash.keys, @fetched_columns)
      model_class = callsite.model_class
      new_rows = model_class.connection.send(:select, sql, "#{model_class.name} Reload SlimScrooged")
      new_rows.each do |row|
        if old_row = rows_hash[row[callsite.primary_key]]
          old_row.slim_result_set = nil
          row.each do |col, value|
            old_row[col] = value
          end
          old_row.instance_variable_set(:@real_hash, MonitoredHash[old_row.to_hash, callsite])
        end
      end
    end
  end

  class MonitoredHash < Hash
    attr_accessor :callsite
    
    def self.[](original_hash, callsite)
      hash = super(original_hash)
      hash.callsite = callsite
      hash
    end
    
    def [](name)
      Callsites.add_seen_column(callsite, name) if @callsite.columns_hash.has_key?(name)
      super
    end
  end
end
