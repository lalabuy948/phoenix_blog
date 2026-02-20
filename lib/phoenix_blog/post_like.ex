defmodule PhoenixBlog.PostLike do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema PhoenixBlog.Config.likes_table_name() do
    field :post_id, :id
    field :user_id, :integer

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(post_like, attrs) do
    post_like
    |> cast(attrs, [:post_id, :user_id])
    |> validate_required([:post_id, :user_id])
    |> unique_constraint([:post_id, :user_id])
  end
end
