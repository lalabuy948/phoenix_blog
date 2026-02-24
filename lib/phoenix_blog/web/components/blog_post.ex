defmodule PhoenixBlog.Web.Components.BlogPost do
  @moduledoc """
  A function component for rendering a single blog post.

  Import and use it in any template:

      import PhoenixBlog.Web.Components.BlogPost

      <.blog_post post={@post} blog_path="/blog" />

  ## Attributes

    * `post` (required) - A `%PhoenixBlog.Post{}` struct
    * `blog_path` - Path to blog index for back/tag links (default: "/blog")
    * `show_back_link` - Show "Back to blog" link (default: true)
    * `show_header` - Show post header with title, tags, author, date (default: true)
    * `show_featured_image` - Show featured image (default: true)
    * `show_tags_footer` - Show tags section at bottom (default: true)
    * `class` - CSS classes for the wrapper article element
  """

  use Phoenix.Component
  import PhoenixBlog.Web.BlogComponents

  attr :post, :map, required: true
  attr :blog_path, :string, default: "/blog"
  attr :show_back_link, :boolean, default: true
  attr :show_header, :boolean, default: true
  attr :show_featured_image, :boolean, default: true
  attr :show_tags_footer, :boolean, default: true
  attr :like_count, :integer, default: nil
  attr :liked, :boolean, default: false
  attr :current_user, :any, default: nil
  attr :class, :string, default: nil

  slot :inner_block

  def blog_post(assigns) do
    ~H"""
    <article class={@class || "max-w-3xl mx-auto px-4 py-6 sm:pb-10"}>
      <%!-- Back link --%>
      <a
        :if={@show_back_link}
        href={@blog_path}
        onclick="if (history.length > 1) { history.back(); return false; }"
        class="inline-flex items-center gap-1 text-sm text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 mb-8 transition-colors"
      >
        &larr; Back to blog
      </a>

      <%!-- Hero Image --%>
      <figure
        :if={@show_featured_image && @post.featured_image_url}
        class="mb-8 rounded-xl overflow-hidden"
      >
        <img
          src={@post.featured_image_url}
          alt={@post.title}
          class="w-full h-auto max-h-96 object-cover"
        />
      </figure>

      <%!-- Header --%>
      <header :if={@show_header} class="mb-10">
        <div class="flex flex-wrap gap-2 mb-4">
          <span
            :for={tag <- @post.tags}
            class="px-2.5 py-0.5 bg-indigo-50 dark:bg-indigo-900/30 text-indigo-700 dark:text-indigo-300 rounded-full text-xs font-medium"
          >
            {tag}
          </span>
        </div>

        <h1 class="text-3xl sm:text-4xl font-bold text-gray-900 dark:text-gray-100 mb-4 leading-tight">
          {@post.title}
        </h1>

        <div class="flex items-center gap-4 text-sm text-gray-500 dark:text-gray-400">
          <span :if={@post.author}>{@post.author}</span>
          <span :if={@post.published_at}>
            {Calendar.strftime(@post.published_at, "%B %d, %Y")}
          </span>
          <%= if @like_count && @current_user do %>
            <button
              phx-click="toggle_like"
              phx-value-post_id={@post.id}
              class={[
                "inline-flex items-center gap-1.5 cursor-pointer transition-colors",
                if(@liked, do: "text-red-500", else: "text-gray-500 dark:text-gray-400 hover:text-red-500")
              ]}
            >
              <svg class="size-4" viewBox="0 0 20 20" fill={if(@liked, do: "currentColor", else: "none")} stroke="currentColor" stroke-width="1.5">
                <path d="M3.172 5.172a4 4 0 015.656 0L10 6.343l1.172-1.171a4 4 0 115.656 5.656L10 17.657l-6.828-6.829a4 4 0 010-5.656z" />
              </svg>
              {@like_count}
            </button>
          <% else %>
            <span :if={@like_count} class="inline-flex items-center gap-1.5 text-gray-500 dark:text-gray-400">
              <svg class="size-4" viewBox="0 0 20 20" fill="currentColor">
                <path d="M3.172 5.172a4 4 0 015.656 0L10 6.343l1.172-1.171a4 4 0 115.656 5.656L10 17.657l-6.828-6.829a4 4 0 010-5.656z" />
              </svg>
              {@like_count}
            </span>
          <% end %>
        </div>
      </header>

      <%!-- Content --%>
      <div class="prose prose-lg dark:prose-invert max-w-none">
        <.render_editor_blocks blocks={Map.get(@post.body, "blocks", [])} />
      </div>

      <%!-- Tags Footer --%>
      <div
        :if={@show_tags_footer && @post.tags != []}
        class="flex flex-wrap gap-2 mt-10"
      >
        <a
          :for={tag <- @post.tags}
          href={"#{@blog_path}?tag=#{tag}"}
          class="px-3 py-1 bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300 rounded-full text-sm hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
        >
          {tag}
        </a>
      </div>

      <%!-- Like / Share (injected by caller) --%>
      {render_slot(@inner_block)}

      <%!-- Back to blog --%>
      <div :if={@show_back_link} class="mt-10 text-center">
        <a
          href={@blog_path}
          onclick="if (history.length > 1) { history.back(); return false; }"
          class="text-indigo-600 dark:text-indigo-400 hover:text-indigo-700 dark:hover:text-indigo-300 text-sm font-medium"
        >
          &larr; Back to all articles
        </a>
      </div>
    </article>
    """
  end
end
