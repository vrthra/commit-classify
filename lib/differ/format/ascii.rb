module Differ
  module Format
    module Ascii
      class << self
        def format(change)
          (change.change? && as_change(change)) ||
          (change.delete? && as_delete(change)) ||
          (change.insert? && as_insert(change)) ||
          ''
        end

      private
        def as_insert(change)
          "<+<#{change.insert}>+>"
        end

        def as_delete(change)
          "<-<#{change.delete}>->"
        end

        def as_change(change)
          "<@<#{change.delete}\t<>\t#{change.insert}>@>"
        end
      end
    end
  end
end
