  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    require Logger
    Logger.debug("Login attempt for email: #{email}")
    
    user = Repo.get_by(User, email: email)
    
    # Log user lookup result
    if user do
      Logger.debug("User found with email: #{email}, checking password")
    else
      Logger.debug("No user found with email: #{email}")
    end
    
    # Only check password if user exists
    password_valid = user && User.valid_password?(user, password)
    
    # Log authentication result
    if password_valid do
      Logger.debug("Password verification successful for user: #{email}")
      user
    else
      if user do
        Logger.debug("Password verification failed for existing user: #{email}")
      end
      nil
    end
  end
