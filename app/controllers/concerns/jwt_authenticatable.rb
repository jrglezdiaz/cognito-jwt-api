module JwtAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_request
  end

  private

  def authenticate_request
    token = extract_token_from_header

    if token.nil?
      render json: { error: "Token not provided" }, status: :unauthorized
      return
    end

    begin
      decoded_token = decode_cognito_token(token)
      @current_user_id = decoded_token["sub"]
      @current_user_email = decoded_token["email"]
      @current_user_username = decoded_token["cognito:username"] || decoded_token["username"]
    rescue JWT::DecodeError => e
      render json: { error: "Invalid token: #{e.message}" }, status: :unauthorized
    rescue JWT::ExpiredSignature
      render json: { error: "Token has expired" }, status: :unauthorized
    rescue JWT::InvalidIssuerError
      render json: { error: "Invalid issuer" }, status: :unauthorized
    rescue JWT::InvalidAudError
      render json: { error: "Invalid audience" }, status: :unauthorized
    rescue StandardError => e
      render json: { error: "Authentication failed: #{e.message}" }, status: :unauthorized
    end
  end

  def extract_token_from_header
    header = request.headers["Authorization"]
    return nil unless header.present?

    # Extract token from "Bearer <token>" format
    header.split(" ").last if header.start_with?("Bearer ")
  end

  def decode_cognito_token(token)
    # Get the JWT key set from Cognito
    jwks_uri = "https://cognito-idp.#{ENV['AWS_REGION']}.amazonaws.com/#{ENV['COGNITO_USER_POOL_ID']}/.well-known/jwks.json"
    jwks_raw = HTTParty.get(jwks_uri)
    jwks = JSON.parse(jwks_raw.body, symbolize_names: true)

    # Decode the token header to get the key ID
    header = JSON.parse(Base64.decode64(token.split(".").first))
    kid = header["kid"]

    # Find the matching key
    key_data = jwks[:keys].find { |key| key[:kid] == kid }

    if key_data.nil?
      raise JWT::DecodeError, "Unable to find a matching key"
    end

    # Convert the key to PEM format
    jwk = JWT::JWK.import(key_data)

    # Decode and verify the token
    JWT.decode(
      token,
      jwk.public_key,
      true,
      {
        algorithm: "RS256",
        iss: "https://cognito-idp.#{ENV['AWS_REGION']}.amazonaws.com/#{ENV['COGNITO_USER_POOL_ID']}",
        verify_iss: true,
        aud: ENV["COGNITO_CLIENT_ID"],
        verify_aud: true,
        verify_expiration: true
      }
    ).first
  end

  def current_user_id
    @current_user_id
  end

  def current_user_email
    @current_user_email
  end

  def current_user_username
    @current_user_username
  end
end
