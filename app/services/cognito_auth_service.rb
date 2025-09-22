class CognitoAuthService
  def initialize
    @client = Aws::CognitoIdentityProvider::Client.new(
      region: ENV["AWS_REGION"],
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
    )
    @client_id = ENV["COGNITO_CLIENT_ID"]
    @client_secret = ENV["COGNITO_CLIENT_SECRET"]
    @user_pool_id = ENV["COGNITO_USER_POOL_ID"]
  end

  def sign_up(username, password, email, name = nil)
    secret_hash = calculate_secret_hash(username)

    attributes = [ { name: "email", value: email } ]
    attributes << { name: "name", value: name } if name.present?

    response = @client.sign_up({
      client_id: @client_id,
      secret_hash: secret_hash,
      username: username,
      password: password,
      user_attributes: attributes
    })

    {
      success: true,
      user_sub: response.user_sub,
      message: "User created successfully. Please check your email for confirmation code."
    }
  rescue Aws::CognitoIdentityProvider::Errors::UsernameExistsException
    { success: false, error: "Username already exists" }
  rescue Aws::CognitoIdentityProvider::Errors::InvalidPasswordException => e
    { success: false, error: e.message }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def confirm_sign_up(username, confirmation_code)
    secret_hash = calculate_secret_hash(username)

    @client.confirm_sign_up({
      client_id: @client_id,
      secret_hash: secret_hash,
      username: username,
      confirmation_code: confirmation_code
    })

    { success: true, message: "User confirmed successfully" }
  rescue Aws::CognitoIdentityProvider::Errors::CodeMismatchException
    { success: false, error: "Invalid confirmation code" }
  rescue Aws::CognitoIdentityProvider::Errors::ExpiredCodeException
    { success: false, error: "Confirmation code has expired" }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def sign_in(username, password)
    secret_hash = calculate_secret_hash(username)

    response = @client.initiate_auth({
      client_id: @client_id,
      auth_flow: "USER_PASSWORD_AUTH",
      auth_parameters: {
        "USERNAME" => username,
        "PASSWORD" => password,
        "SECRET_HASH" => secret_hash
      }
    })

    if response.authentication_result
      {
        success: true,
        access_token: response.authentication_result.access_token,
        id_token: response.authentication_result.id_token,
        refresh_token: response.authentication_result.refresh_token,
        expires_in: response.authentication_result.expires_in
      }
    elsif response.challenge_name
      {
        success: false,
        challenge: response.challenge_name,
        session: response.session,
        message: "Authentication challenge required"
      }
    end
  rescue Aws::CognitoIdentityProvider::Errors::NotAuthorizedException
    { success: false, error: "Invalid username or password" }
  rescue Aws::CognitoIdentityProvider::Errors::UserNotFoundException
    { success: false, error: "User not found" }
  rescue Aws::CognitoIdentityProvider::Errors::UserNotConfirmedException
    { success: false, error: "User not confirmed. Please confirm your account" }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def refresh_token(refresh_token)
    secret_hash = calculate_secret_hash_for_refresh(refresh_token)

    response = @client.initiate_auth({
      client_id: @client_id,
      auth_flow: "REFRESH_TOKEN_AUTH",
      auth_parameters: {
        "REFRESH_TOKEN" => refresh_token,
        "SECRET_HASH" => secret_hash
      }
    })

    {
      success: true,
      access_token: response.authentication_result.access_token,
      id_token: response.authentication_result.id_token,
      expires_in: response.authentication_result.expires_in
    }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def sign_out(access_token)
    @client.global_sign_out({
      access_token: access_token
    })

    { success: true, message: "User signed out successfully" }
  rescue Aws::CognitoIdentityProvider::Errors::NotAuthorizedException
    { success: false, error: "Invalid or expired token" }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def forgot_password(username)
    secret_hash = calculate_secret_hash(username)

    response = @client.forgot_password({
      client_id: @client_id,
      secret_hash: secret_hash,
      username: username
    })

    {
      success: true,
      message: "Password reset code sent to your email",
      delivery: response.code_delivery_details
    }
  rescue Aws::CognitoIdentityProvider::Errors::UserNotFoundException
    { success: false, error: "User not found" }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def confirm_forgot_password(username, confirmation_code, new_password)
    secret_hash = calculate_secret_hash(username)

    @client.confirm_forgot_password({
      client_id: @client_id,
      secret_hash: secret_hash,
      username: username,
      confirmation_code: confirmation_code,
      password: new_password
    })

    { success: true, message: "Password reset successfully" }
  rescue Aws::CognitoIdentityProvider::Errors::CodeMismatchException
    { success: false, error: "Invalid confirmation code" }
  rescue Aws::CognitoIdentityProvider::Errors::ExpiredCodeException
    { success: false, error: "Confirmation code has expired" }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def get_user(access_token)
    response = @client.get_user({
      access_token: access_token
    })

    {
      success: true,
      username: response.username,
      attributes: response.user_attributes.map { |attr| { attr.name => attr.value } }.reduce(&:merge),
      mfa_options: response.mfa_options
    }
  rescue Aws::CognitoIdentityProvider::Errors::NotAuthorizedException
    { success: false, error: "Invalid or expired token" }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def change_password(access_token, previous_password, new_password)
    @client.change_password({
      access_token: access_token,
      previous_password: previous_password,
      proposed_password: new_password
    })

    { success: true, message: "Password changed successfully" }
  rescue Aws::CognitoIdentityProvider::Errors::NotAuthorizedException
    { success: false, error: "Invalid or expired token" }
  rescue Aws::CognitoIdentityProvider::Errors::InvalidPasswordException => e
    { success: false, error: e.message }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  private

  def calculate_secret_hash(username)
    return nil unless @client_secret.present?

    message = username + @client_id
    secret = @client_secret

    Base64.strict_encode64(
      OpenSSL::HMAC.digest("sha256", secret, message)
    )
  end

  def calculate_secret_hash_for_refresh(refresh_token)
    # For refresh token, we need to extract the username from the token
    # This is a simplified version, in production you might need to decode the token
    # or store the username separately
    return nil unless @client_secret.present?

    # Using client_id as the message for refresh token
    message = @client_id
    secret = @client_secret

    Base64.strict_encode64(
      OpenSSL::HMAC.digest("sha256", secret, message)
    )
  end
end
