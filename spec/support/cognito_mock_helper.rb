module CognitoMockHelper
  def stub_cognito_jwks
    jwks = {
      keys: [
        {
          alg: "RS256",
          e: "AQAB",
          kid: "test-key-id",
          kty: "RSA",
          n: "test-key-n",
          use: "sig"
        }
      ]
    }

    stub_request(:get, "https://cognito-idp.#{ENV['AWS_REGION']}.amazonaws.com/#{ENV['COGNITO_USER_POOL_ID']}/.well-known/jwks.json")
      .to_return(status: 200, body: jwks.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  def stub_cognito_sign_up_success
    response = {
      user_sub: "test-user-sub-id",
      code_delivery_details: {
        destination: "test@example.com",
        delivery_medium: "EMAIL",
        attribute_name: "email"
      }
    }

    allow_any_instance_of(Aws::CognitoIdentityProvider::Client).to receive(:sign_up).and_return(response)
  end

  def stub_cognito_sign_in_success
    response = OpenStruct.new(
      authentication_result: OpenStruct.new(
        access_token: "test-access-token",
        id_token: "test-id-token",
        refresh_token: "test-refresh-token",
        expires_in: 3600
      )
    )

    allow_any_instance_of(Aws::CognitoIdentityProvider::Client).to receive(:initiate_auth).and_return(response)
  end

  def stub_cognito_get_user_success
    response = OpenStruct.new(
      username: "testuser",
      user_attributes: [
        OpenStruct.new(name: "sub", value: "test-user-id"),
        OpenStruct.new(name: "email", value: "test@example.com"),
        OpenStruct.new(name: "email_verified", value: "true"),
        OpenStruct.new(name: "name", value: "Test User")
      ],
      mfa_options: []
    )

    allow_any_instance_of(Aws::CognitoIdentityProvider::Client).to receive(:get_user).and_return(response)
  end
end

RSpec.configure do |config|
  config.include CognitoMockHelper
end
