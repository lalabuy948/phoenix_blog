defmodule PhoenixBlog.Web.Hooks.SetAssigns do
  @moduledoc false

  import Phoenix.Component

  def on_mount({:set_blog_path, path}, _params, _session, socket) do
    {:cont,
     socket
     |> assign(:blog_path, path)
     |> assign(:dashboard_path, nil)
     |> assign(:phoenix_blog_context, :public)
     |> maybe_assign_current_user()}
  end

  def on_mount({:set_dashboard_path, path}, _params, _session, socket) do
    {:cont,
     socket
     |> assign(:dashboard_path, path)
     |> assign(:blog_path, nil)
     |> assign(:phoenix_blog_context, :admin)
     |> maybe_assign_current_user()}
  end

  defp maybe_assign_current_user(socket) do
    if PhoenixBlog.Config.likes_enabled?() do
      get_user_fn = PhoenixBlog.Config.get_current_user()
      user = get_user_fn.(socket)
      assign(socket, :phoenix_blog_current_user, user)
    else
      assign(socket, :phoenix_blog_current_user, nil)
    end
  end
end
