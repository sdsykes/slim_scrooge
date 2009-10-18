# Author: Stephen Sykes

module SlimScrooge
  class Callsites
    CallsitesMutex = Mutex.new
    @@callsites = {}

    class << self
      def [](callsite_key)
        @@callsites[callsite_key]
      end

      def callsite_key(callsite_hash, sql)
        callsite_hash + sql.hash
      end

      def find_or_create(sql, callsite_key, name)
        if @@callsites.has_key? callsite_key
          @@callsites[callsite_key]
        else
          if name
            class_name = name.split.first
            model_class = class_name.constantize
            add_callsite(callsite_key, Callsite.make_callsite(model_class, sql))
          else
            add_callsite(callsite_key, nil)
          end
        end
      rescue NameError # from constantize
        add_callsite(callsite_key, nil)
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
