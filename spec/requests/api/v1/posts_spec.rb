require 'rails_helper'

RSpec.describe 'Api::V1::Posts', type: :request do
  let(:user_id) { 'test-user-123' }
  let(:other_user_id) { 'other-user-456' }
  let(:headers) { valid_headers(generate_test_token(user_id: user_id)) }

  # Mock JWT authentication for tests
  before do
    allow_any_instance_of(ApplicationController).to receive(:authenticate_request).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user_id).and_return(user_id)
    allow_any_instance_of(ApplicationController).to receive(:current_user_email).and_return('test@example.com')
    allow_any_instance_of(ApplicationController).to receive(:current_user_username).and_return('testuser')
  end

  describe 'GET /api/v1/posts' do
    let!(:my_published_post) { create(:post, :published, user_id: user_id) }
    let!(:my_unpublished_post) { create(:post, :unpublished, user_id: user_id) }
    let!(:other_published_post) { create(:post, :published, user_id: other_user_id) }
    let!(:other_unpublished_post) { create(:post, :unpublished, user_id: other_user_id) }

    before { get '/api/v1/posts', headers: headers }

    it 'returns published posts and current user posts' do
      expect(response).to have_http_status(:ok)
      post_ids = json.map { |p| p['id'] }

      expect(post_ids).to include(my_published_post.id)
      expect(post_ids).to include(my_unpublished_post.id)
      expect(post_ids).to include(other_published_post.id)
      expect(post_ids).not_to include(other_unpublished_post.id)
    end
  end

  describe 'GET /api/v1/posts/:id' do
    context 'when accessing own post' do
      let(:post) { create(:post, :unpublished, user_id: user_id) }

      before { get "/api/v1/posts/#{post.id}", headers: headers }

      it 'returns the post' do
        expect(response).to have_http_status(:ok)
        expect(json['id']).to eq(post.id)
      end
    end

    context 'when accessing published post from another user' do
      let(:post) { create(:post, :published, user_id: other_user_id) }

      before { get "/api/v1/posts/#{post.id}", headers: headers }

      it 'returns the post' do
        expect(response).to have_http_status(:ok)
        expect(json['id']).to eq(post.id)
      end
    end

    context 'when accessing unpublished post from another user' do
      let(:post) { create(:post, :unpublished, user_id: other_user_id) }

      before { get "/api/v1/posts/#{post.id}", headers: headers }

      it 'returns forbidden' do
        expect(response).to have_http_status(:forbidden)
        expect(json['error']).to include('Not authorized')
      end
    end

    context 'when post does not exist' do
      before { get '/api/v1/posts/999999', headers: headers }

      it 'returns not found' do
        expect(response).to have_http_status(:not_found)
        expect(json['error']).to include('not found')
      end
    end
  end

  describe 'POST /api/v1/posts' do
    let(:valid_params) do
      {
        post: {
          title: 'Test Post',
          content: 'This is a test post content',
          published: true
        }
      }
    end

    let(:invalid_params) do
      {
        post: {
          title: '',
          content: ''
        }
      }
    end

    context 'with valid params' do
      before { post '/api/v1/posts', params: valid_params.to_json, headers: headers }

      it 'creates a post' do
        expect(response).to have_http_status(:created)
        expect(json['title']).to eq('Test Post')
        expect(json['user_id']).to eq(user_id)
      end
    end

    context 'with invalid params' do
      before { post '/api/v1/posts', params: invalid_params.to_json, headers: headers }

      it 'returns unprocessable entity' do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json['errors']).not_to be_empty
      end
    end
  end

  describe 'PUT /api/v1/posts/:id' do
    let(:update_params) do
      {
        post: {
          title: 'Updated Title',
          content: 'Updated content'
        }
      }
    end

    context 'when updating own post' do
      let(:post) { create(:post, user_id: user_id) }

      before { put "/api/v1/posts/#{post.id}", params: update_params.to_json, headers: headers }

      it 'updates the post' do
        expect(response).to have_http_status(:ok)
        expect(json['title']).to eq('Updated Title')
      end
    end

    context 'when updating another user post' do
      let(:post) { create(:post, user_id: other_user_id) }

      before { put "/api/v1/posts/#{post.id}", params: update_params.to_json, headers: headers }

      it 'returns forbidden' do
        expect(response).to have_http_status(:forbidden)
        expect(json['error']).to include('Not authorized')
      end
    end
  end

  describe 'DELETE /api/v1/posts/:id' do
    context 'when deleting own post' do
      let!(:post) { create(:post, user_id: user_id) }

      it 'deletes the post' do
        expect {
          delete "/api/v1/posts/#{post.id}", headers: headers
        }.to change(Post, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end
    end

    context 'when deleting another user post' do
      let(:post) { create(:post, user_id: other_user_id) }

      before { delete "/api/v1/posts/#{post.id}", headers: headers }

      it 'returns forbidden' do
        expect(response).to have_http_status(:forbidden)
        expect(json['error']).to include('Not authorized')
      end
    end
  end

  describe 'GET /api/v1/posts/my_posts' do
    let!(:my_posts) { create_list(:post, 3, user_id: user_id) }
    let!(:other_posts) { create_list(:post, 2, user_id: other_user_id) }

    before { get '/api/v1/posts/my_posts', headers: headers }

    it 'returns only current user posts' do
      expect(response).to have_http_status(:ok)
      expect(json.size).to eq(3)

      returned_user_ids = json.map { |p| p['user_id'] }.uniq
      expect(returned_user_ids).to eq([ user_id ])
    end
  end
end
