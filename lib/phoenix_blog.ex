defmodule PhoenixBlog do
  @moduledoc """
  Plug-and-play blog engine for Phoenix with Editor.js integration.

  ## Setup

  1. Add `{:phoenix_blog, "~> 0.1"}` to your `mix.exs`
  2. Configure: `config :phoenix_blog, repo: MyApp.Repo`
  3. Create and run the migration (see `PhoenixBlog.Migration`)
  4. Mount routes in your router (see `PhoenixBlog.Web.Router`)
  """

  import Ecto.Query, warn: false

  alias PhoenixBlog.Post
  alias PhoenixBlog.Repo, as: BlogRepo

  defp repo, do: BlogRepo.repo()

  # ============================================
  # Public Queries
  # ============================================

  @doc """
  Returns published posts for public display with pagination.

  ## Options

    * `:page` - Page number (default: 1)
    * `:per_page` - Items per page (default: 12)
    * `:search` - Search by title
    * `:tag` - Filter by tag

  """
  def list_published_posts(opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 12)
    search = Keyword.get(opts, :search)
    tag = Keyword.get(opts, :tag)

    now = DateTime.utc_now(:second)

    Post
    |> where([p], p.status == :published)
    |> where([p], is_nil(p.deleted_at))
    |> where([p], p.published_at <= ^now)
    |> apply_search_filter(search)
    |> apply_tag_filter(tag)
    |> order_by([p], desc: p.published_at)
    |> paginate(page, per_page)
  end

  @doc """
  Returns the count of published posts matching the given filters.
  """
  def count_published_posts(opts \\ []) do
    search = Keyword.get(opts, :search)
    tag = Keyword.get(opts, :tag)

    now = DateTime.utc_now(:second)

    Post
    |> where([p], p.status == :published)
    |> where([p], is_nil(p.deleted_at))
    |> where([p], p.published_at <= ^now)
    |> apply_search_filter(search)
    |> apply_tag_filter(tag)
    |> repo().aggregate(:count)
  end

  @doc """
  Gets a single published post by slug.

  Raises `Ecto.NoResultsError` if the post does not exist.
  """
  def get_post_by_slug!(slug) do
    now = DateTime.utc_now(:second)

    Post
    |> where([p], p.slug == ^slug)
    |> where([p], p.status == :published)
    |> where([p], is_nil(p.deleted_at))
    |> where([p], p.published_at <= ^now)
    |> repo().one!()
  end

  @doc """
  Returns all unique tags from published posts, sorted alphabetically.
  """
  def list_published_tags do
    now = DateTime.utc_now(:second)

    Post
    |> where([p], p.status == :published)
    |> where([p], is_nil(p.deleted_at))
    |> where([p], p.published_at <= ^now)
    |> select([p], p.tags)
    |> repo().all()
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc """
  Returns the latest N published posts.
  """
  def list_latest_published_posts(limit \\ 4) do
    now = DateTime.utc_now(:second)

    Post
    |> where([p], p.status == :published)
    |> where([p], is_nil(p.deleted_at))
    |> where([p], p.published_at <= ^now)
    |> order_by([p], desc: p.published_at)
    |> limit(^limit)
    |> repo().all()
  end

  # ============================================
  # Admin Queries
  # ============================================

  @doc """
  Returns posts for admin with optional filters and pagination.

  ## Options

    * `:page` - Page number (default: 1)
    * `:per_page` - Items per page (default: 20)
    * `:status` - Filter by status
    * `:search` - Search by title
    * `:tag` - Filter by tag
    * `:show_deleted` - Include soft-deleted posts (default: false)

  """
  def list_posts(opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 20)
    status = Keyword.get(opts, :status)
    search = Keyword.get(opts, :search)
    tag = Keyword.get(opts, :tag)
    show_deleted = Keyword.get(opts, :show_deleted, false)

    Post
    |> apply_status_filter(status)
    |> apply_search_filter(search)
    |> apply_tag_filter(tag)
    |> apply_deleted_filter(show_deleted)
    |> order_by([p], desc: p.inserted_at)
    |> paginate(page, per_page)
  end

  @doc """
  Returns the count of posts matching the given admin filters.
  """
  def count_posts(opts \\ []) do
    status = Keyword.get(opts, :status)
    search = Keyword.get(opts, :search)
    tag = Keyword.get(opts, :tag)
    show_deleted = Keyword.get(opts, :show_deleted, false)

    Post
    |> apply_status_filter(status)
    |> apply_search_filter(search)
    |> apply_tag_filter(tag)
    |> apply_deleted_filter(show_deleted)
    |> repo().aggregate(:count)
  end

  @doc """
  Gets a single post by ID.

  Raises `Ecto.NoResultsError` if the post does not exist.
  """
  def get_post!(id) do
    repo().get!(Post, id)
  end

  @doc """
  Gets a single post by slug (admin version, no status/deleted filters).
  """
  def get_post_by_slug_admin(slug) do
    Post
    |> where([p], p.slug == ^slug)
    |> repo().one()
  end

  # ============================================
  # Create / Update / Delete
  # ============================================

  @doc """
  Creates a post.
  """
  def create_post(attrs) do
    %Post{}
    |> Post.changeset(attrs)
    |> repo().insert()
  end

  @doc """
  Updates a post.
  """
  def update_post(%Post{} = post, attrs) do
    post
    |> Post.changeset(attrs)
    |> repo().update()
  end

  @doc """
  Publishes a post.
  """
  def publish_post(%Post{} = post) do
    post
    |> Post.publish_changeset()
    |> repo().update()
  end

  @doc """
  Soft deletes a post.
  """
  def soft_delete_post(%Post{} = post) do
    post
    |> Post.soft_delete_changeset()
    |> repo().update()
  end

  @doc """
  Restores a soft-deleted post.
  """
  def restore_post(%Post{} = post) do
    post
    |> Post.restore_changeset()
    |> repo().update()
  end

  @doc """
  Deletes a post permanently.
  """
  def delete_post(%Post{} = post) do
    repo().delete(post)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking post changes.
  """
  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end

  # ============================================
  # Private Helpers
  # ============================================

  defp apply_status_filter(query, nil), do: query
  defp apply_status_filter(query, ""), do: query

  defp apply_status_filter(query, status) when is_binary(status) do
    status_atom = String.to_existing_atom(status)
    where(query, [p], p.status == ^status_atom)
  end

  defp apply_status_filter(query, status) when is_atom(status) do
    where(query, [p], p.status == ^status)
  end

  defp apply_search_filter(query, nil), do: query
  defp apply_search_filter(query, ""), do: query

  defp apply_search_filter(query, search) do
    search_term = "%#{search}%"

    case BlogRepo.adapter_type() do
      :postgres ->
        where(query, [p], ilike(p.title, ^search_term))

      _other ->
        where(
          query,
          [p],
          fragment("LOWER(?) LIKE LOWER(?)", p.title, ^search_term)
        )
    end
  end

  defp apply_tag_filter(query, nil), do: query
  defp apply_tag_filter(query, ""), do: query

  defp apply_tag_filter(query, tag) do
    case BlogRepo.adapter_type() do
      :postgres ->
        where(query, [p], ^tag in p.tags)

      _other ->
        where(
          query,
          [p],
          fragment("? LIKE ?", p.tags, ^"%\"#{tag}\"%")
        )
    end
  end

  defp apply_deleted_filter(query, true), do: query

  defp apply_deleted_filter(query, false) do
    where(query, [p], is_nil(p.deleted_at))
  end

  defp paginate(query, page, per_page) do
    offset = (page - 1) * per_page

    query
    |> limit(^per_page)
    |> offset(^offset)
    |> repo().all()
  end
end
