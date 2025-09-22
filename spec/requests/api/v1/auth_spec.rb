require 'rails_helper'

RSpec.describe 'Api::V1::Auth', type: :request do
  describe 'POST /api/v1/auth/signup' do
    let(:valid_params) do
      {
        auth: {
          username: 'testuser',
          password: 'Password123!',
          email: 'test@example.com',
          name: 'Test User'
        }
      }
    end

    let(:invalid_params) do
      {
        auth: {
          username: '',
          password: 'weak',
          email: 'invalid'
        }
      }
    end

    context 'when the request is valid' do
      before do
        stub_cognito_sign_up_success
        post '/api/v1/auth/signup', params: valid_params.to_json, headers: { 'Content-Type' => 'application/json' }
      end

      it 'creates a user and returns user_sub' do
        expect(response).to have_http_status(:created)
        expect(json['user_sub']).not_to be_nil
        expect(json['message']).to include('successfully')
      end
    end

    context 'when the request is invalid' do
      before do
        allow_any_instance_of(Aws::CognitoIdentityProvider::Client)
          .to receive(:sign_up)
          .and_raise(Aws::CognitoIdentityProvider::Errors::InvalidPasswordException.new(nil, 'Password weak'))

        post '/api/v1/auth/signup', params: invalid_params.to_json, headers: { 'Content-Type' => 'application/json' }
      end

      it 'returns an error message' do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json['error']).not_to be_nil
      end
    end
  end

  describe 'POST /api/v1/auth/signin' do
    let(:valid_credentials) do
      {
        auth: {
          username: 'testuser',
          password: 'Password123!'
        }
      }
    end

    let(:invalid_credentials) do
      {
        auth: {
          username: 'testuser',
          password: 'wrongpassword'
        }
      }
    end

    context 'with valid credentials' do
      before do
        stub_cognito_sign_in_success
        post '/api/v1/auth/signin', params: valid_credentials.to_json, headers: { 'Content-Type' => 'application/json' }
      end

      it 'returns tokens' do
        expect(response).to have_http_status(:ok)
        expect(json['access_token']).not_to be_nil
        expect(json['id_token']).not_to be_nil
        expect(json['refresh_token']).not_to be_nil
        expect(json['expires_in']).to eq(3600)
      end
    end

    context 'with invalid credentials' do
      before do
        allow_any_instance_of(Aws::CognitoIdentityProvider::Client)
          .to receive(:initiate_auth)
          .and_raise(Aws::CognitoIdentityProvider::Errors::NotAuthorizedException.new(nil, 'Incorrect username or password'))

        post '/api/v1/auth/signin', params: invalid_credentials.to_json, headers: { 'Content-Type' => 'application/json' }
      end

      it 'returns unauthorized' do
        expect(response).to have_http_status(:unauthorized)
        expect(json['error']).to eq('Invalid username or password')
      end
    end
  end

  describe 'POST /api/v1/auth/signout' do
    context 'with valid token' do
      before do
        allow_any_instance_of(Aws::CognitoIdentityProvider::Client)
          .to receive(:global_sign_out)
          .and_return(true)

        post '/api/v1/auth/signout', headers: auth_headers
      end

      it 'signs out successfully' do
        expect(response).to have_http_status(:ok)
        expect(json['message']).to include('signed out successfully')
      end
    end

    context 'with invalid token' do
      before do
        allow_any_instance_of(Aws::CognitoIdentityProvider::Client)
          .to receive(:global_sign_out)
          .and_raise(Aws::CognitoIdentityProvider::Errors::NotAuthorizedException.new(nil, 'Invalid token'))

        post '/api/v1/auth/signout', headers: auth_headers('invalid_token')
      end

      it 'returns error' do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json['error']).to include('Invalid or expired token')
      end
    end
  end

  describe 'POST /api/v1/auth/refresh' do
    let(:refresh_params) do
      {
        auth: {
          refresh_token: 'valid_refresh_token'
        }
      }
    end

    context 'with valid refresh token' do
      before do
        response_mock = OpenStruct.new(
          authentication_result: OpenStruct.new(
            access_token: 'new_access_token',
            id_token: 'new_id_token',
            expires_in: 3600
          )
        )

        allow_any_instance_of(Aws::CognitoIdentityProvider::Client)
          .to receive(:initiate_auth)
          .and_return(response_mock)

        post '/api/v1/auth/refresh', params: refresh_params.to_json, headers: { 'Content-Type' => 'application/json' }
      end

      it 'returns new tokens' do
        expect(response).to have_http_status(:ok)
        expect(json['access_token']).to eq('new_access_token')
        expect(json['id_token']).to eq('new_id_token')
        expect(json['expires_in']).to eq(3600)
      end
    end
  end
end
