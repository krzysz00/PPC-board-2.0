class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :authentication_keys => [ :name ]
#         :openid_authenticatable #Don't feel like dealing with this

  before_create :de_guest
  after_create :welcome_mail

  has_many :posts, dependent: :nullify
  has_one :ban, dependent: :nullify
  has_and_belongs_to_many :watched_posts, -> { uniq }, :class_name => 'Post'

  validates :name, :presence => true
  validates :name, :uniqueness => true
  validates_length_of :name, :maximum => 80
  validate :check_email_ban

  def email_changed?
    false
  end

  private
  def de_guest
    self.guest_user = false
    true
  end

  def welcome_mail
    BoardMailer.welcome_email(self).deliver_now
  end

  def check_email_ban
    if Ban.find_ban(:email => self.email)
      errors[:email] << "is banned."
    end
  end
end
