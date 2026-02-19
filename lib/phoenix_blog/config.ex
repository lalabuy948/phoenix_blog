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

  def site_name do
    Application.get_env(:phoenix_blog, :site_name, "Blog")
  end

  def default_og_image do
    Application.get_env(:phoenix_blog, :default_og_image, nil)
  end

  def twitter_site do
    Application.get_env(:phoenix_blog, :twitter_site, nil)
  end

  def locale do
    Application.get_env(:phoenix_blog, :locale, "en_US")
  end
end
