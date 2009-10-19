# Author: Stephen Sykes

module SlimScrooge
  class Callsites
    CallsitesMutex = Mutex.new
    @@callsites = {}

    class << self
      def has_key?(callsite_key)
        @@callsites.has_key?(callsite_key)
      end

      def [](callsite_key)
        @@callsites[callsite_key]
      end

      def callsite_key(callsite_hash, sql)
        callsite_hash + sql.gsub(/WHERE.*/i, "").hash
      end

      def create(sql, callsite_key, name)
        begin
          model_class = name.split.first.constantize
        rescue NameError, NoMethodError
          add_callsite(callsite_key, nil)
        else
          add_callsite(callsite_key, Callsite.make_callsite(model_class, sql))
        end
      end

      def add_callsite(callsite_key, callsite)
        CallsitesMutex.synchronize do
          @@callsites[callsite_key] = callsite
        end
      end

      def add_seen_column(callsite, seen_column)
        CallsitesMutex.synchronize do
          callsite.seen_columns << seen_column
        end
      end
    end
  end
end
