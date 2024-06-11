class Company < ApplicationRecord
  has_many :company_integration
  has_many :user, dependent: :destroy
  has_many :integration, :through => :company_integration
end
