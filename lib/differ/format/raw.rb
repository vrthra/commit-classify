module Differ
  module Format
    module Raw
      class << self
        def format(change)
          change.to_hash
        end
      end
    end
  end
end
