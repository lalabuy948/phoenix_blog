defmodule PhoenixBlog.Config do
  @moduledoc false

  def repo do
    Application.get_env(:phoenix_blog, :repo) ||
      raise """
      PhoenixBlog requires a repo to be configured.

      Add the following to your config:

          config :phoenix_blog, repo: MyApp.Repo
      """
  end

  def table_name do
    Application.get_env(:phoenix_blog, :table_name, "phoenix_blog_posts")
  end
end
