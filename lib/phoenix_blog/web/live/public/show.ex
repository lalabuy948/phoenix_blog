defmodule PhoenixBlog.Web.Live.Public.Show do
  use PhoenixBlog.Web, :live_view

  import PhoenixBlog.Web.Components.BlogPost

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"slug" => slug}, uri, socket) do
    post = PhoenixBlog.get_post_by_slug!(slug)

    {:noreply,
     socket
     |> assign(:post, post)
     |> assign(:page_title, post.title)
     |> PhoenixBlog.Web.SEO.assign_seo(post, uri)}
  rescue
    Ecto.NoResultsError ->
      {:noreply,
       socket
       |> put_flash(:error, "Post not found")
       |> push_navigate(to: socket.assigns.blog_path || "/")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-white dark:bg-gray-950">
      <.blog_post post={@post} blog_path={@blog_path} />
    </div>
    """
  end
end
