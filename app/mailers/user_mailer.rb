class UserMailer < ApplicationMailer
  default from: 'noreply.75way@gmail.com'
  
  def welcome_email(user, url)
    @user = user
    @url  = url
    mail(to: @user.email, subject: 'Reset your password')
 end
end
