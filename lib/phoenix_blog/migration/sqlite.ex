defmodule PhoenixBlog.Migration.SQLite do
  @moduledoc false

  use Ecto.Migration

  def up(version \\ 1, opts \\ [])

  def up(1, _opts) do
    table_name = PhoenixBlog.Config.table_name()

    create table(table_name) do
      add :title, :string, null: false
      add :slug, :string, null: false
      add :body, :text, null: false
      add :status, :string, null: false, default: "draft"
      add :tags, :text, default: "[]"
      add :seo_description, :text
      add :featured_image_url, :string
      add :author, :string
      add :published_at, :utc_datetime
      add :deleted_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(table_name, [:slug])
    create index(table_name, [:status])
    create index(table_name, [:published_at])
    create index(table_name, [:deleted_at])
  end

  def up(2, _opts) do
    likes_table = PhoenixBlog.Config.likes_table_name()
    posts_table = PhoenixBlog.Config.table_name()

    create table(likes_table) do
      add :post_id, references(posts_table, on_delete: :delete_all), null: false
      add :user_id, :integer, null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(likes_table, [:post_id, :user_id])
    create index(likes_table, [:user_id])
  end

  def down(version \\ 1, opts \\ [])

  def down(1, _opts) do
    table_name = PhoenixBlog.Config.table_name()
    drop_if_exists table(table_name)
  end

  def down(2, _opts) do
    likes_table = PhoenixBlog.Config.likes_table_name()
    drop_if_exists table(likes_table)
  end
end
