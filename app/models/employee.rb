class Employee < ApplicationRecord
  has_many :employee_integrations
  has_many :activity_log
  has_one_attached :image
  accepts_nested_attributes_for :employee_integrations, allow_destroy: true
end
