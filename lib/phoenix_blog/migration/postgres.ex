defmodule PhoenixBlog.Migration.Postgres do
  @moduledoc false

  use Ecto.Migration

  def up(_opts \\ []) do
    table_name = PhoenixBlog.Config.table_name()

    create table(table_name) do
      add :title, :string, null: false
      add :slug, :string, null: false
      add :body, :map, null: false
      add :status, :string, null: false, default: "draft"
      add :tags, {:array, :string}, default: []
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

  def down(_opts \\ []) do
    table_name = PhoenixBlog.Config.table_name()
    drop_if_exists table(table_name)
  end
end
