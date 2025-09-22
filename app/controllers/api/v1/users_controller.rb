class Api::V1::UsersController < ApplicationController
  # This controller is protected by default through ApplicationController
  # All actions require a valid JWT token from Cognito

  def profile
    # Get user information from Cognito using the access token
    token = extract_token_from_header
    result = cognito_service.get_user(token)

    if result[:success]
      render json: {
        username: result[:username],
        attributes: result[:attributes],
        cognito_id: current_user_id,
        email: current_user_email
      }, status: :ok
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  def current
    # Return current user information from the JWT token
    render json: {
      user_id: current_user_id,
      email: current_user_email,
      username: current_user_username
    }, status: :ok
  end

  private

  def cognito_service
    @cognito_service ||= CognitoAuthService.new
  end

  def extract_token_from_header
    header = request.headers["Authorization"]
    return nil unless header.present?
    header.split(" ").last if header.start_with?("Bearer ")
  end
end
