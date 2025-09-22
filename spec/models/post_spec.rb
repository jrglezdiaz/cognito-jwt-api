require 'rails_helper'

RSpec.describe Post, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:content) }
    it { should validate_presence_of(:user_id) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:post)).to be_valid
    end

    it 'creates a published post' do
      post = create(:post, :published)
      expect(post.published).to be true
    end

    it 'creates an unpublished post' do
      post = create(:post, :unpublished)
      expect(post.published).to be false
    end
  end

  describe 'scopes' do
    let!(:published_post) { create(:post, :published) }
    let!(:unpublished_post) { create(:post, :unpublished) }

    it 'returns published posts' do
      expect(Post.where(published: true)).to include(published_post)
      expect(Post.where(published: true)).not_to include(unpublished_post)
    end
  end
end
