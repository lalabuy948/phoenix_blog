defmodule PhoenixBlog.Web.Components.BlogFeed do
  @moduledoc """
  A self-contained blog feed LiveComponent with search, tag filters, and pagination.

  Embed it in any host app LiveView:

      <.live_component
        module={PhoenixBlog.Web.Components.BlogFeed}
        id="blog-feed"
        blog_path="/blog"
      />

  ## Customization with slots

  Override the default post card rendering:

      <.live_component
        module={PhoenixBlog.Web.Components.BlogFeed}
        id="blog-feed"
        blog_path="/blog"
      >
        <:post_card :let={post}>
          <div class="my-custom-card">
            <h3>{post.title}</h3>
          </div>
        </:post_card>
      </.live_component>

  ## Attributes

    * `blog_path` (required) - The path where your blog is mounted
    * `per_page` - Items per page (default: 12)
    * `show_search` - Show search bar (default: true)
    * `show_tags` - Show tag filter buttons (default: true)
    * `show_hero` - Show hero banner with title and count (default: false)
    * `class` - Additional CSS classes for the wrapper
    * `grid_class` - CSS classes for the posts grid container

  ## Slots

    * `:post_card` - Custom rendering for each post card. Receives the post via `:let`.
    * `:empty` - Custom empty state content.
  """

  use Phoenix.LiveComponent
  import PhoenixBlog.Web.CoreComponents
  import PhoenixBlog.Web.BlogComponents, only: [extract_excerpt: 1]

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:per_page, fn -> 12 end)
      |> assign_new(:show_search, fn -> true end)
      |> assign_new(:show_tags, fn -> true end)
      |> assign_new(:show_hero, fn -> false end)
      |> assign_new(:class, fn -> nil end)
      |> assign_new(:grid_class, fn -> "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6" end)
      |> assign_new(:page, fn -> 1 end)
      |> assign_new(:search, fn -> "" end)
      |> assign_new(:tag_filter, fn -> nil end)
      |> assign_new(:loaded?, fn -> false end)

    socket =
      if not socket.assigns.loaded? do
        socket
        |> assign(:loaded?, true)
        |> load_posts()
      else
        socket
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    {:noreply,
     socket
     |> assign(:search, search)
     |> assign(:page, 1)
     |> load_posts()}
  end

  def handle_event("filter_tag", %{"tag" => tag}, socket) do
    tag_filter = if tag == "" or tag == "all", do: nil, else: tag

    {:noreply,
     socket
     |> assign(:tag_filter, tag_filter)
     |> assign(:page, 1)
     |> load_posts()}
  end

  def handle_event("prev_page", _, socket) do
    page = max(socket.assigns.page - 1, 1)

    {:noreply,
     socket
     |> assign(:page, page)
     |> load_posts()}
  end

  def handle_event("next_page", _, socket) do
    page = min(socket.assigns.page + 1, socket.assigns.total_pages)

    {:noreply,
     socket
     |> assign(:page, page)
     |> load_posts()}
  end

  defp load_posts(socket) do
    per_page = socket.assigns.per_page

    opts = [
      page: socket.assigns.page,
      per_page: per_page,
      tag: socket.assigns.tag_filter,
      search: socket.assigns.search
    ]

    posts = PhoenixBlog.list_published_posts(opts)
    total_count = PhoenixBlog.count_published_posts(opts)
    total_pages = ceil(total_count / per_page)
    all_tags = PhoenixBlog.list_published_tags()

    likes_enabled = PhoenixBlog.Config.likes_enabled?()

    like_counts =
      if likes_enabled do
        post_ids = Enum.map(posts, & &1.id)
        PhoenixBlog.like_counts_for_posts(post_ids)
      else
        %{}
      end

    socket
    |> assign(:total_count, total_count)
    |> assign(:total_pages, max(total_pages, 1))
    |> assign(:all_tags, all_tags)
    |> assign(:posts, posts)
    |> assign(:posts_empty?, posts == [])
    |> assign(:likes_enabled, likes_enabled)
    |> assign(:like_counts, like_counts)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class={@class}>
      <%!-- Hero --%>
      <section
        :if={@show_hero}
        class="bg-gradient-to-br from-indigo-600 via-purple-600 to-purple-700 pt-16 sm:pt-20 mb-10 -mx-4 sm:-mx-6 lg:-mx-8 px-4 sm:px-6 lg:px-8"
        style={if(@show_search, do: "padding-bottom: 3.5rem;", else: "padding-bottom: 4rem;")}
      >
        <div class="max-w-5xl mx-auto text-center">
          <h1 class="text-4xl sm:text-5xl font-extrabold text-white tracking-tight mb-3">Blog</h1>
          <p class="text-lg text-indigo-100/90 max-w-2xl mx-auto mb-8">
            <%= cond do %>
              <% @total_count == 0 -> %>
                No articles yet
              <% @total_count == 1 -> %>
                1 article published
              <% true -> %>
                {@total_count} articles published
            <% end %>
          </p>
          <%!-- Search inside hero --%>
          <.form
            :if={@show_search}
            for={%{}}
            phx-change="search"
            phx-submit="search"
            phx-target={@myself}
            id={"#{@id}-search"}
            class="relative max-w-lg mx-auto"
          >
            <input
              type="text"
              placeholder="Search articles..."
              phx-debounce="300"
              name="search"
              value={@search}
              class="w-full pl-12 pr-4 py-3.5 text-base text-gray-900 dark:text-gray-100 bg-white dark:bg-gray-800 rounded-xl border-0 shadow-lg focus:ring-2 focus:ring-white/50 placeholder:text-gray-400"
            />
            <.icon
              name="hero-magnifying-glass"
              class="absolute left-4 top-1/2 -translate-y-1/2 size-5 text-gray-400"
            />
          </.form>
        </div>
      </section>

      <%!-- Search (standalone when hero is hidden) --%>
      <.form
        :if={@show_search && !@show_hero}
        for={%{}}
        phx-change="search"
        phx-submit="search"
        phx-target={@myself}
        id={"#{@id}-search-standalone"}
        class="relative max-w-lg mx-auto mb-8"
      >
        <input
          type="text"
          placeholder="Search articles..."
          phx-debounce="300"
          name="search"
          value={@search}
          class="w-full pl-12 pr-4 py-3.5 text-base text-gray-900 dark:text-gray-100 bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm focus:ring-2 focus:ring-indigo-300 placeholder:text-gray-400"
        />
        <.icon
          name="hero-magnifying-glass"
          class="absolute left-4 top-1/2 -translate-y-1/2 size-5 text-gray-400"
        />
      </.form>

      <%!-- Tag Filters --%>
      <div :if={@show_tags && @all_tags != []} class="flex flex-wrap justify-center gap-2 pb-2 mb-8">
        <button
          phx-click="filter_tag"
          phx-value-tag="all"
          phx-target={@myself}
          class={[
            "px-4 py-2 rounded-full text-sm font-medium transition-all whitespace-nowrap",
            if(is_nil(@tag_filter),
              do: "bg-indigo-600 text-white shadow",
              else:
                "bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-700"
            )
          ]}
        >
          All
        </button>
        <button
          :for={tag <- @all_tags}
          phx-click="filter_tag"
          phx-value-tag={tag}
          phx-target={@myself}
          class={[
            "px-4 py-2 rounded-full text-sm font-medium transition-all whitespace-nowrap",
            if(@tag_filter == tag,
              do: "bg-indigo-600 text-white shadow",
              else:
                "bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-700"
            )
          ]}
        >
          {String.capitalize(tag)}
        </button>
      </div>

      <%!-- Empty State --%>
      <%= if @posts_empty? do %>
        <%= if assigns[:empty] && assigns[:empty] != [] do %>
          {render_slot(@empty)}
        <% else %>
          <div class="text-center py-24">
            <div class="w-20 h-20 mx-auto mb-5 rounded-2xl bg-gray-100 dark:bg-gray-800 flex items-center justify-center">
              <.icon name="hero-document-text" class="size-9 text-gray-400" />
            </div>
            <h3 class="text-xl font-semibold text-gray-900 dark:text-gray-100 mb-2">
              No articles found
            </h3>
            <p class="text-gray-500 dark:text-gray-400 max-w-sm mx-auto">
              Try adjusting your search or filters to find what you're looking for.
            </p>
          </div>
        <% end %>
      <% else %>
        <%!-- Posts Grid --%>
        <div class={@grid_class}>
          <%= for post <- @posts do %>
            <%= if assigns[:post_card] && assigns[:post_card] != [] do %>
              {render_slot(@post_card, Map.put(post, :like_count, Map.get(@like_counts, post.id, 0)))}
            <% else %>
              <a
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

                  <h2 class="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-2 group-hover:text-indigo-600 dark:group-hover:text-indigo-400 transition-colors line-clamp-2">
                    {post.title}
                  </h2>

                  <p class="text-sm text-gray-500 dark:text-gray-400 line-clamp-3 mb-4 flex-1">
                    {extract_excerpt(post)}
                  </p>

                  <div class="grid grid-cols-3 items-center pt-3 border-t border-gray-100 dark:border-gray-800 text-xs text-gray-400 dark:text-gray-500">
                    <span>{post.author}</span>
                    <span class="text-center whitespace-nowrap">
                      <%= if post.published_at do %>
                        {Calendar.strftime(post.published_at, "%B %d, %Y")}
                      <% end %>
                    </span>
                    <span class="inline-flex items-center gap-1 justify-end">
                      <%= if @likes_enabled do %>
                        <svg class="size-3.5" viewBox="0 0 20 20" fill="currentColor">
                          <path d="M3.172 5.172a4 4 0 015.656 0L10 6.343l1.172-1.171a4 4 0 115.656 5.656L10 17.657l-6.828-6.829a4 4 0 010-5.656z" />
                        </svg>
                        {Map.get(@like_counts, post.id, 0)}
                      <% end %>
                    </span>
                  </div>
                </div>
              </a>
            <% end %>
          <% end %>
        </div>

        <%!-- Pagination --%>
        <nav
          :if={@total_pages > 1}
          class="flex items-center justify-center gap-3 mt-12 pt-8 border-t border-gray-100 dark:border-gray-800"
        >
          <button
            phx-click="prev_page"
            phx-target={@myself}
            disabled={@page == 1}
            class={[
              "inline-flex items-center gap-1.5 px-5 py-2.5 rounded-lg text-sm font-medium transition-all",
              if(@page == 1,
                do: "opacity-40 cursor-not-allowed text-gray-400",
                else:
                  "text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-700 shadow-sm"
              )
            ]}
          >
            <.icon name="hero-chevron-left" class="size-4" /> Previous
          </button>

          <span class="px-4 py-2 text-sm font-medium text-gray-600 dark:text-gray-400 tabular-nums">
            {@page} / {@total_pages}
          </span>

          <button
            phx-click="next_page"
            phx-target={@myself}
            disabled={@page >= @total_pages}
            class={[
              "inline-flex items-center gap-1.5 px-5 py-2.5 rounded-lg text-sm font-medium transition-all",
              if(@page >= @total_pages,
                do: "opacity-40 cursor-not-allowed text-gray-400",
                else:
                  "text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-700 shadow-sm"
              )
            ]}
          >
            Next <.icon name="hero-chevron-right" class="size-4" />
          </button>
        </nav>
      <% end %>
    </div>
    """
  end
end
