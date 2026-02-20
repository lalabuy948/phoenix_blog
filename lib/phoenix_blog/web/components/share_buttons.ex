defmodule PhoenixBlog.Web.Components.ShareButtons do
  @moduledoc false

  use Phoenix.Component

  attr :url, :string, required: true
  attr :title, :string, required: true
  attr :class, :string, default: nil

  def share_buttons(assigns) do
    assigns =
      assigns
      |> assign(:encoded_url, URI.encode_www_form(assigns.url))
      |> assign(:encoded_title, URI.encode_www_form(assigns.title))

    ~H"""
    <div class={["flex items-center gap-2", @class]}>
      <span class="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider mr-1">
        Share
      </span>

      <%!-- Copy link --%>
      <button
        id="copy-link-btn"
        phx-hook="PhoenixBlogCopyLink"
        phx-update="ignore"
        data-url={@url}
        class="inline-flex items-center justify-center size-8 rounded-full bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-gray-700 hover:text-gray-900 dark:hover:text-gray-100 transition-all"
        title="Copy link"
      >
        <svg class="size-4" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M13.19 8.688a4.5 4.5 0 0 1 1.242 7.244l-4.5 4.5a4.5 4.5 0 0 1-6.364-6.364l1.757-1.757m13.35-.622 1.757-1.757a4.5 4.5 0 0 0-6.364-6.364l-4.5 4.5a4.5 4.5 0 0 0 1.242 7.244"
          />
        </svg>
      </button>

      <%!-- Twitter/X --%>
      <a
        href={"https://twitter.com/intent/tweet?url=#{@encoded_url}&text=#{@encoded_title}"}
        target="_blank"
        rel="noopener noreferrer"
        class="inline-flex items-center justify-center size-8 rounded-full bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-gray-700 hover:text-gray-900 dark:hover:text-gray-100 transition-all"
        title="Share on X"
      >
        <svg class="size-3.5" viewBox="0 0 24 24" fill="currentColor">
          <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
        </svg>
      </a>

      <%!-- Facebook --%>
      <a
        href={"https://www.facebook.com/sharer/sharer.php?u=#{@encoded_url}"}
        target="_blank"
        rel="noopener noreferrer"
        class="inline-flex items-center justify-center size-8 rounded-full bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-gray-700 hover:text-gray-900 dark:hover:text-gray-100 transition-all"
        title="Share on Facebook"
      >
        <svg class="size-3.5" viewBox="0 0 24 24" fill="currentColor">
          <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" />
        </svg>
      </a>

      <%!-- LinkedIn --%>
      <a
        href={"https://www.linkedin.com/sharing/share-offsite/?url=#{@encoded_url}"}
        target="_blank"
        rel="noopener noreferrer"
        class="inline-flex items-center justify-center size-8 rounded-full bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-gray-700 hover:text-gray-900 dark:hover:text-gray-100 transition-all"
        title="Share on LinkedIn"
      >
        <svg class="size-3.5" viewBox="0 0 24 24" fill="currentColor">
          <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z" />
        </svg>
      </a>
    </div>
    """
  end
end
