defmodule PhoenixBlog.Web.Router do
  @moduledoc """
  Router macros for mounting PhoenixBlog in your application.

  ## Usage

      # In your router.ex
      use PhoenixBlog.Web, :router

      scope "/" do
        pipe_through :browser
        phoenix_blog "/blog"
      end

      scope "/" do
        pipe_through [:browser, :require_authenticated_user]
        phoenix_blog_dashboard "/blog/admin",
          on_mount: [{MyAppWeb.UserAuth, :require_authenticated}]
      end
  """

  @doc """
  Mounts the public blog routes at the given path.

  ## Options

    * `:on_mount` - Additional on_mount hooks (default: [])
    * `:as` - Live session name (default: :phoenix_blog)
    * `:layout` - Override the layout module
    * `:index_view` - Custom LiveView module for the blog index (default: `PhoenixBlog.Web.Live.Public.Index`)
    * `:show_view` - Custom LiveView module for the blog post page (default: `PhoenixBlog.Web.Live.Public.Show`)

  ## Examples

      # Default
      phoenix_blog "/blog"

      # Custom views
      phoenix_blog "/blog",
        index_view: MyAppWeb.CustomBlogIndex,
        show_view: MyAppWeb.CustomBlogShow
  """
  defmacro phoenix_blog(path, opts \\ []) do
    quote bind_quoted: [path: path, opts: opts] do
      custom_on_mount = Keyword.get(opts, :on_mount, [])
      session_name = Keyword.get(opts, :as, :phoenix_blog)
      layout = Keyword.get(opts, :layout)
      index_view = Keyword.get(opts, :index_view, PhoenixBlog.Web.Live.Public.Index)
      show_view = Keyword.get(opts, :show_view, PhoenixBlog.Web.Live.Public.Show)

      on_mount =
        [{PhoenixBlog.Web.Hooks.SetAssigns, {:set_blog_path, path}}] ++ custom_on_mount

      session_opts =
        [on_mount: on_mount]
        |> then(fn opts -> if layout, do: Keyword.put(opts, :layout, layout), else: opts end)

      scope path, alias: false, as: false do
        live_session session_name, session_opts do
          live "/", index_view, :index
          live "/:slug", show_view, :show
        end
      end
    end
  end

  @doc """
  Mounts the admin blog dashboard routes at the given path.

  Accepts `on_mount` option for authentication hooks.
  Accepts `layout` option to wrap blog pages in your app layout.

  Routes:
    * `GET <path>` - Admin post index
    * `GET <path>/new` - New post form
    * `GET <path>/:id/edit` - Edit post form
  """
  defmacro phoenix_blog_dashboard(path, opts \\ []) do
    quote bind_quoted: [path: path, opts: opts] do
      custom_on_mount = Keyword.get(opts, :on_mount, [])
      session_name = Keyword.get(opts, :as, :phoenix_blog_dashboard)
      layout = Keyword.get(opts, :layout)

      on_mount =
        [{PhoenixBlog.Web.Hooks.SetAssigns, {:set_dashboard_path, path}}] ++ custom_on_mount

      session_opts =
        [on_mount: on_mount]
        |> then(fn opts -> if layout, do: Keyword.put(opts, :layout, layout), else: opts end)

      scope path, alias: false, as: false do
        live_session session_name, session_opts do
          live "/", PhoenixBlog.Web.Live.Admin.Index, :index
          live "/new", PhoenixBlog.Web.Live.Admin.Form, :new
          live "/:id/edit", PhoenixBlog.Web.Live.Admin.Form, :edit
        end
      end
    end
  end
end
