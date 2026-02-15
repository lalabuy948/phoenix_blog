defmodule PhoenixBlog.Web.Hooks.SetAssigns do
  @moduledoc false

  import Phoenix.Component

  def on_mount({:set_blog_path, path}, _params, _session, socket) do
    {:cont,
     socket
     |> assign(:blog_path, path)
     |> assign(:dashboard_path, nil)
     |> assign(:phoenix_blog_context, :public)}
  end

  def on_mount({:set_dashboard_path, path}, _params, _session, socket) do
    {:cont,
     socket
     |> assign(:dashboard_path, path)
     |> assign(:blog_path, nil)
     |> assign(:phoenix_blog_context, :admin)}
  end
end
