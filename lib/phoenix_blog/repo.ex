defmodule PhoenixBlog.Repo do
  @moduledoc false

  def repo do
    PhoenixBlog.Config.repo()
  end

  def adapter_type do
    adapter = repo().__adapter__()

    cond do
      adapter == Ecto.Adapters.Postgres -> :postgres
      adapter == Ecto.Adapters.MyXQL -> :mysql
      adapter == Ecto.Adapters.SQLite3 -> :sqlite
      true -> raise "PhoenixBlog: unsupported Ecto adapter #{inspect(adapter)}"
    end
  end
end
