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
  attr :class, :string, default: nil

  def blog_post(assigns) do
    ~H"""
    <article class={@class || "max-w-3xl mx-auto px-4 py-12 sm:py-16"}>
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
        </div>
      </header>

      <%!-- Content --%>
      <div class="prose prose-lg dark:prose-invert max-w-none">
        <.render_editor_blocks blocks={Map.get(@post.body, "blocks", [])} />
      </div>

      <%!-- Tags Footer --%>
      <div
        :if={@show_tags_footer && @post.tags != []}
        class="border-t border-gray-200 dark:border-gray-700 pt-8 mt-12"
      >
        <h3 class="text-sm font-semibold text-gray-900 dark:text-gray-100 mb-3">Tags</h3>
        <div class="flex flex-wrap gap-2">
          <a
            :for={tag <- @post.tags}
            href={"#{@blog_path}?tag=#{tag}"}
            class="px-3 py-1 bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300 rounded-full text-sm hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
          >
            {tag}
          </a>
        </div>
      </div>

      <%!-- Back to blog --%>
      <div :if={@show_back_link} class="mt-12 text-center">
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
