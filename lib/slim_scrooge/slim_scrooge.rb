# Author: Stephen Sykes

module SlimScrooge
  module SelectAll
    def self.included(base)
      base.alias_method_chain :select_all, :slim_scrooge
    end

    def select_all_with_slim_scrooge(sql, name = nil)
      callsite_key = SlimScrooge::Callsites.callsite_key(callsite_hash, sql)
      if SlimScrooge::Callsites.has_key?(callsite_key)
        if callsite = SlimScrooge::Callsites[callsite_key]
          seen_columns = callsite.seen_columns.dup
          rows = select_all_without_slim_scrooge(callsite.scrooged_sql(seen_columns, sql), name + " SlimScrooged")
          result_set = SlimScrooge::ResultSet.new(rows.dup, callsite_key, seen_columns)
          rows.each {|row| row.real_hash = MonitoredHash[{}, callsite, result_set]}
        else
          select_all_without_slim_scrooge(sql, name)
        end
      elsif callsite = SlimScrooge::Callsites.create(sql, callsite_key, name)
        rows = select_all_without_slim_scrooge(sql, name + " SlimScrooged 1st time")
        rows.each {|row| row.real_hash = MonitoredHash[row.to_hash, callsite, nil]}
        rows
      else
        select_all_without_slim_scrooge(sql, name)
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::MysqlAdapter.send(:include, SlimScrooge::SelectAll)
