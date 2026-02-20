defmodule PhoenixBlog.Post do
  @moduledoc """
  Ecto schema for blog posts.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @statuses [:draft, :published, :archived]

  schema PhoenixBlog.Config.table_name() do
    field :title, :string
    field :slug, :string
    field :body, :map
    field :status, Ecto.Enum, values: @statuses, default: :draft
    field :tags, {:array, :string}, default: []
    field :seo_description, :string
    field :featured_image_url, :string
    field :author, :string
    field :published_at, :utc_datetime
    field :deleted_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  def published?(%__MODULE__{status: :published}), do: true
  def published?(_), do: false

  def deleted?(%__MODULE__{deleted_at: nil}), do: false
  def deleted?(%__MODULE__{deleted_at: _}), do: true

  def changeset(post, attrs) do
    post
    |> cast(attrs, [
      :title,
      :slug,
      :body,
      :status,
      :tags,
      :seo_description,
      :featured_image_url,
      :author,
      :published_at
    ])
    |> validate_required([:title, :slug, :body, :status])
    |> validate_slug()
    |> validate_length(:seo_description, max: 300)
    |> normalize_tags()
    |> maybe_set_published_at()
    |> unique_constraint(:slug)
  end

  def publish_changeset(post) do
    now = DateTime.utc_now(:second)
    change(post, status: :published, published_at: now)
  end

  def soft_delete_changeset(post) do
    now = DateTime.utc_now(:second)
    change(post, deleted_at: now)
  end

  def restore_changeset(post) do
    change(post, deleted_at: nil)
  end

  def slugify(string) do
    string
    |> String.downcase()
    |> String.replace(~r/[^\w\s-]/u, "")
    |> String.replace(~r/\s+/, "-")
    |> String.replace(~r/-+/, "-")
    |> String.trim("-")
  end

  # Private helpers

  defp validate_slug(changeset) do
    changeset
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/,
      message: "must contain only lowercase letters, numbers, and hyphens"
    )
    |> validate_length(:slug, min: 3, max: 200)
  end

  defp maybe_set_published_at(changeset) do
    status = get_field(changeset, :status)
    published_at = get_field(changeset, :published_at)

    if status == :published and is_nil(published_at) do
      put_change(changeset, :published_at, DateTime.utc_now(:second))
    else
      changeset
    end
  end

  defp normalize_tags(changeset) do
    case get_change(changeset, :tags) do
      nil ->
        changeset

      tags when is_list(tags) ->
        normalized =
          tags
          |> Enum.map(&String.trim/1)
          |> Enum.map(&String.downcase/1)
          |> Enum.reject(&(&1 == ""))
          |> Enum.uniq()

        put_change(changeset, :tags, normalized)

      _other ->
        changeset
    end
  end
end
