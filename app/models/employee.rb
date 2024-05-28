class Employee < ApplicationRecord
  has_many :employee_integration
  has_one_attached :image
  accepts_nested_attributes_for :employee_integration, allow_destroy: true
end
