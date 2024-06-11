class User < ApplicationRecord
  attr_accessor :skip_password_validation
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable
  belongs_to :role
  has_many :activity_log, :foreign_key => 'created_by', dependent: :destroy
  belongs_to :company

  protected

  def password_required?
    return false if skip_password_validation
    super
  end
end
