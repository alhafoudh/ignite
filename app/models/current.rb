class Current < ActiveSupport::CurrentAttributes
  attribute :config

  resets { self.config = nil }
end
