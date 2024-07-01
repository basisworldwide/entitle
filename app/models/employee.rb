class Employee < ApplicationRecord
  has_many :employee_integrations, dependent: :destroy
  has_many :activity_log, dependent: :destroy
  has_one_attached :image, dependent: :destroy
  accepts_nested_attributes_for :employee_integrations, allow_destroy: true
  validates_uniqueness_of :employee_id, message: "Id can\'t be same"
end
