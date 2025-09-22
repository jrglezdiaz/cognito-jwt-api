class Api::V1::PostsController < ApplicationController
  before_action :set_post, only: [ :show, :update, :destroy ]

  # GET /api/v1/posts
  def index
    @posts = Post.where(published: true).or(Post.where(user_id: current_user_id))
    render json: @posts
  end

  # GET /api/v1/posts/:id
  def show
    if can_access_post?(@post)
      render json: @post
    else
      render json: { error: "Not authorized to view this post" }, status: :forbidden
    end
  end

  # POST /api/v1/posts
  def create
    @post = Post.new(post_params)
    @post.user_id = current_user_id

    if @post.save
      render json: @post, status: :created
    else
      render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/posts/:id
  def update
    if @post.user_id != current_user_id
      render json: { error: "Not authorized to update this post" }, status: :forbidden
      return
    end

    if @post.update(post_params)
      render json: @post
    else
      render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/posts/:id
  def destroy
    if @post.user_id != current_user_id
      render json: { error: "Not authorized to delete this post" }, status: :forbidden
      return
    end

    @post.destroy
    head :no_content
  end

  # GET /api/v1/posts/my_posts
  def my_posts
    @posts = Post.where(user_id: current_user_id)
    render json: @posts
  end

  private

  def set_post
    @post = Post.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Post not found" }, status: :not_found
  end

  def post_params
    params.require(:post).permit(:title, :content, :published)
  end

  def can_access_post?(post)
    post.published || post.user_id == current_user_id
  end
end
