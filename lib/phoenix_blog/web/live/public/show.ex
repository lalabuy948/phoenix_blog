defmodule PhoenixBlog.Web.Live.Public.Show do
  use PhoenixBlog.Web, :live_view

  import PhoenixBlog.Web.Components.BlogPost
  import PhoenixBlog.Web.Components.LikeButton
  import PhoenixBlog.Web.Components.ShareButtons

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"slug" => slug}, uri, socket) do
    post = PhoenixBlog.get_post_by_slug!(slug)
    likes_enabled = PhoenixBlog.Config.likes_enabled?()
    share_enabled = PhoenixBlog.Config.share_enabled?()

    current_user = socket.assigns[:phoenix_blog_current_user]
    user_id = if current_user, do: current_user.id

    {:noreply,
     socket
     |> assign(:post, post)
     |> assign(:page_title, post.title)
     |> assign(:current_url, uri)
     |> assign(:likes_enabled, likes_enabled)
     |> assign(:share_enabled, share_enabled)
     |> assign(
       :like_count,
       if(likes_enabled, do: PhoenixBlog.like_count(post.id), else: 0)
     )
     |> assign(
       :liked,
       if(likes_enabled, do: PhoenixBlog.liked_by_user?(post.id, user_id), else: false)
     )
     |> PhoenixBlog.Web.SEO.assign_seo(post, uri)}
  rescue
    Ecto.NoResultsError ->
      {:noreply,
       socket
       |> put_flash(:error, "Post not found")
       |> push_navigate(to: socket.assigns.blog_path || "/")}
  end

  @impl true
  def handle_event("toggle_like", %{"post_id" => post_id_str}, socket) do
    current_user = socket.assigns[:phoenix_blog_current_user]

    if current_user && socket.assigns.likes_enabled do
      post_id = String.to_integer(post_id_str)

      case PhoenixBlog.toggle_like(post_id, current_user.id) do
        {:ok, :liked} ->
          {:noreply,
           socket
           |> assign(:liked, true)
           |> assign(:like_count, socket.assigns.like_count + 1)}

        {:ok, :unliked} ->
          {:noreply,
           socket
           |> assign(:liked, false)
           |> assign(:like_count, max(socket.assigns.like_count - 1, 0))}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Could not process your like")}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-white dark:bg-gray-950">
      <.blog_post post={@post} blog_path={@blog_path} like_count={if(@likes_enabled, do: @like_count)} liked={@liked} current_user={@phoenix_blog_current_user}>
        <div
          :if={@likes_enabled or @share_enabled}
          class="flex items-center justify-between border-t border-gray-200 dark:border-gray-800 mt-10 pt-4"
        >
          <.like_button
            :if={@likes_enabled}
            post_id={@post.id}
            like_count={@like_count}
            liked={@liked}
            current_user={@phoenix_blog_current_user}
          />
          <div :if={@likes_enabled and not @share_enabled} />
          <.share_buttons :if={@share_enabled} url={@current_url} title={@post.title} />
        </div>
      </.blog_post>
    </div>
    """
  end
end
