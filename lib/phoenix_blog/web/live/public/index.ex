defmodule PhoenixBlog.Web.Live.Public.Index do
  use PhoenixBlog.Web, :live_view

  alias PhoenixBlog.Web.Components.BlogFeed

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Blog")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 dark:bg-gray-950">
      <section class="py-12 sm:py-16">
        <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
          <.live_component
            module={BlogFeed}
            id="blog-index-feed"
            blog_path={@blog_path}
            show_hero={true}
          />
        </div>
      </section>
    </div>
    """
  end
end
