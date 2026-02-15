defmodule PhoenixBlog.Web.Live.Public.Show do
  use PhoenixBlog.Web, :live_view

  import PhoenixBlog.Web.Components.BlogPost

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    try do
      post = PhoenixBlog.get_post_by_slug!(slug)

      socket =
        socket
        |> assign(:post, post)
        |> assign(:page_title, post.title)

      {:ok, socket}
    rescue
      Ecto.NoResultsError ->
        {:ok,
         socket
         |> put_flash(:error, "Post not found")
         |> redirect(to: socket.assigns.blog_path || "/")}
    end
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
