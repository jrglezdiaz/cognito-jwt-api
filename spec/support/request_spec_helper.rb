module RequestSpecHelper
  # Parse JSON response
  def json
    JSON.parse(response.body)
  end

  # Generate JWT token for testing
  def generate_test_token(user_id: 'test-user-id', email: 'test@example.com', username: 'testuser')
    payload = {
      sub: user_id,
      email: email,
      'cognito:username': username,
      exp: 1.hour.from_now.to_i,
      iat: Time.now.to_i,
      iss: "https://cognito-idp.#{ENV['AWS_REGION']}.amazonaws.com/#{ENV['COGNITO_USER_POOL_ID']}",
      aud: ENV['COGNITO_CLIENT_ID']
    }

    JWT.encode(payload, test_jwt_secret, 'HS256')
  end

  # Authorization header helper
  def auth_headers(token = nil)
    token ||= generate_test_token
    { 'Authorization' => "Bearer #{token}" }
  end

  # Valid headers with content type
  def valid_headers(token = nil)
    auth_headers(token).merge('Content-Type' => 'application/json')
  end

  private

  def test_jwt_secret
    'test_secret_key_for_testing_only'
  end
end
