module ReaderWriter
  extend ActiveSupport::Concern

  included do
    field :ispublic, type: Boolean, default: false

    def readable?(user)
      readers.include?(user) || writers.include?(user) || user.vip || self.ispublic
    end

    def writable?(user)
      writers.include?(user) || user.vip || self.ispublic
    end
  end
end