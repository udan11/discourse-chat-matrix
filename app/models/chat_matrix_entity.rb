# frozen_string_literal: true

class ChatMatrixEntity < ActiveRecord::Base
  belongs_to :entity, polymorphic: true
end
