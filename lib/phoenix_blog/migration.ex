defmodule PhoenixBlog.Migration do
  @moduledoc """
  Migrations for PhoenixBlog.

  ## Usage

  Create a migration in your host application:

      defmodule MyApp.Repo.Migrations.AddPhoenixBlog do
        use Ecto.Migration

        def up, do: PhoenixBlog.Migration.up()
        def down, do: PhoenixBlog.Migration.down()
      end

  Then run `mix ecto.migrate`.
  """

  def up(opts \\ []) do
    version = Keyword.get(opts, :version, 1)
    migrator().up(version, opts)
  end

  def down(opts \\ []) do
    version = Keyword.get(opts, :version, 1)
    migrator().down(version, opts)
  end

  defp migrator do
    case PhoenixBlog.Repo.adapter_type() do
      :postgres -> PhoenixBlog.Migration.Postgres
      :mysql -> PhoenixBlog.Migration.MySQL
      :sqlite -> PhoenixBlog.Migration.SQLite
    end
  end
end
