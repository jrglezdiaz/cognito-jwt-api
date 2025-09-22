class Api::V1::AuthController < ApplicationController
  skip_before_action :authenticate_request, only: [ :sign_up, :sign_in, :confirm_sign_up, :forgot_password, :confirm_forgot_password, :refresh ]

  def sign_up
    result = cognito_service.sign_up(
      sign_up_params[:username],
      sign_up_params[:password],
      sign_up_params[:email],
      sign_up_params[:name]
    )

    if result[:success]
      render json: {
        message: result[:message],
        user_sub: result[:user_sub]
      }, status: :created
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  def confirm_sign_up
    result = cognito_service.confirm_sign_up(
      confirm_params[:username],
      confirm_params[:confirmation_code]
    )

    if result[:success]
      render json: { message: result[:message] }, status: :ok
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  def sign_in
    result = cognito_service.sign_in(
      sign_in_params[:username],
      sign_in_params[:password]
    )

    if result[:success]
      render json: {
        access_token: result[:access_token],
        id_token: result[:id_token],
        refresh_token: result[:refresh_token],
        expires_in: result[:expires_in]
      }, status: :ok
    elsif result[:challenge]
      render json: {
        challenge: result[:challenge],
        session: result[:session],
        message: result[:message]
      }, status: :ok
    else
      render json: { error: result[:error] }, status: :unauthorized
    end
  end

  def sign_out
    token = extract_token_from_header
    result = cognito_service.sign_out(token)

    if result[:success]
      render json: { message: result[:message] }, status: :ok
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  def refresh
    result = cognito_service.refresh_token(refresh_params[:refresh_token])

    if result[:success]
      render json: {
        access_token: result[:access_token],
        id_token: result[:id_token],
        expires_in: result[:expires_in]
      }, status: :ok
    else
      render json: { error: result[:error] }, status: :unauthorized
    end
  end

  def forgot_password
    result = cognito_service.forgot_password(forgot_password_params[:username])

    if result[:success]
      render json: {
        message: result[:message],
        delivery: result[:delivery]
      }, status: :ok
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  def confirm_forgot_password
    result = cognito_service.confirm_forgot_password(
      confirm_forgot_password_params[:username],
      confirm_forgot_password_params[:confirmation_code],
      confirm_forgot_password_params[:new_password]
    )

    if result[:success]
      render json: { message: result[:message] }, status: :ok
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  def change_password
    token = extract_token_from_header
    result = cognito_service.change_password(
      token,
      change_password_params[:previous_password],
      change_password_params[:new_password]
    )

    if result[:success]
      render json: { message: result[:message] }, status: :ok
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  private

  def cognito_service
    @cognito_service ||= CognitoAuthService.new
  end

  def sign_up_params
    params.require(:auth).permit(:username, :password, :email, :name)
  end

  def confirm_params
    params.require(:auth).permit(:username, :confirmation_code)
  end

  def sign_in_params
    params.require(:auth).permit(:username, :password)
  end

  def refresh_params
    params.require(:auth).permit(:refresh_token)
  end

  def forgot_password_params
    params.require(:auth).permit(:username)
  end

  def confirm_forgot_password_params
    params.require(:auth).permit(:username, :confirmation_code, :new_password)
  end

  def change_password_params
    params.require(:auth).permit(:previous_password, :new_password)
  end

  def extract_token_from_header
    header = request.headers["Authorization"]
    return nil unless header.present?
    header.split(" ").last if header.start_with?("Bearer ")
  end
end
