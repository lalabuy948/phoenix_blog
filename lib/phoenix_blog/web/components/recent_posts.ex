defmodule PhoenixBlog.Web.Components.RecentPosts do
  @moduledoc """
  A LiveComponent that displays the latest blog posts.

  Embed it in any LiveView page to show recent posts:

      <.live_component
        module={PhoenixBlog.Web.Components.RecentPosts}
        id="recent-posts"
        blog_path="/blog"
      />

  ## Attributes

    * `blog_path` (required) - The path where your blog is mounted
    * `count` - Number of posts to show (default: 3)
    * `title` - Section title (default: "Latest Posts")
    * `class` - Additional CSS classes for the wrapper
  """

  use Phoenix.LiveComponent
  import PhoenixBlog.Web.BlogComponents, only: [extract_excerpt: 1]

  @impl true
  def update(assigns, socket) do
    count = Map.get(assigns, :count, 3)
    posts = PhoenixBlog.list_latest_published_posts(count)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:title, fn -> "Latest Posts" end)
     |> assign_new(:class, fn -> nil end)
     |> assign(:posts, posts)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class={@class}>
      <h2 :if={@title} class="text-2xl font-bold text-gray-900 dark:text-gray-100 mb-6">{@title}</h2>

      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
        <a
          :for={post <- @posts}
          href={"#{@blog_path}/#{post.slug}"}
          data-phx-link="redirect"
          data-phx-link-state="push"
          class="group flex flex-col rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-900 hover:shadow-lg hover:-translate-y-0.5 transition-all overflow-hidden"
        >
          <figure :if={post.featured_image_url} class="h-48 overflow-hidden">
            <img
              src={post.featured_image_url}
              alt={post.title}
              class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
            />
          </figure>

          <div class="p-5 flex flex-col flex-1">
            <div :if={post.tags != []} class="flex flex-wrap gap-1.5 mb-3">
              <span
                :for={tag <- Enum.take(post.tags, 2)}
                class="px-2 py-0.5 bg-indigo-50 dark:bg-indigo-900/30 text-indigo-700 dark:text-indigo-300 rounded text-xs font-medium"
              >
                {tag}
              </span>
            </div>

            <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-2 group-hover:text-indigo-600 dark:group-hover:text-indigo-400 transition-colors line-clamp-2">
              {post.title}
            </h3>

            <p class="text-sm text-gray-500 dark:text-gray-400 line-clamp-3 mb-4 flex-1">
              {extract_excerpt(post)}
            </p>

            <div class="flex items-center justify-between pt-3 border-t border-gray-100 dark:border-gray-800 text-xs text-gray-400 dark:text-gray-500">
              <span :if={post.author}>{post.author}</span>
              <span :if={post.published_at}>
                {Calendar.strftime(post.published_at, "%B %d, %Y")}
              </span>
            </div>
          </div>
        </a>
      </div>

      <div :if={@posts == []} class="text-center py-8 text-gray-500 dark:text-gray-400">
        No posts yet.
      </div>
    </section>
    """
  end

end
