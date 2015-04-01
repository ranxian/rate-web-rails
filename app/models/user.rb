class User
  include Mongoid::Document

  # 用户名
  field :name, type: String

  has_many :generated_views, class_name: 'View', inverse_of: 'generator'
  has_many :generated_benches, class_name: 'Bench', inverse_of: 'generator'
  has_many :algorithms, inverse_of: 'author'
  has_many :tasks, inverse_of: 'runner'

  has_and_belongs_to_many :reading_benches, class_name: 'Bench', inverse_of: 'readers'
  has_and_belongs_to_many :writing_benches, class_name: 'Bench', inverse_of: 'writers'
  has_and_belongs_to_many :reading_views, class_name: 'View', inverse_of: 'readers'
  has_and_belongs_to_many :writing_views, class_name: 'View', inverse_of: 'writers'
  has_and_belongs_to_many :reading_algorithms, class_name: 'Algorithm', inverse_of: 'readers'
  has_and_belongs_to_many :writing_algorithms, class_name: 'Algorithm', inverse_of: 'writers'

  ################
  #### Devise ####
  ################
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  ## Database authenticatable
  field :email,              type: String, default: ""
  field :encrypted_password, type: String, default: ""

  ## Recoverable
  field :reset_password_token,   type: String
  field :reset_password_sent_at, type: Time

  ## Rememberable
  field :remember_created_at, type: Time

  ## Trackable
  field :sign_in_count,      type: Integer, default: 0
  field :current_sign_in_at, type: Time
  field :last_sign_in_at,    type: Time
  field :current_sign_in_ip, type: String
  field :last_sign_in_ip,    type: String

  ## Confirmable
  # field :confirmation_token,   type: String
  # field :confirmed_at,         type: Time
  # field :confirmation_sent_at, type: Time
  # field :unconfirmed_email,    type: String # Only if using reconfirmable

  ## Lockable
  # field :failed_attempts, type: Integer, default: 0 # Only if lock strategy is :failed_attempts
  # field :unlock_token,    type: String # Only if unlock strategy is :email or :both
  # field :locked_at,       type: Time
end
