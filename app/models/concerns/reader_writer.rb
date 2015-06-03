module ReaderWriter
  extend ActiveSupport::Concern

  included do
    field :ispublic, type: Boolean, default: false

    scope :published, -> { where(ispublic: true) }

    def readable?(user)
      readers.include?(user) || writers.include?(user) || user.vip || self.ispublic
    end

    def writable?(user)
      writers.include?(user) || user.vip
    end
  end
end