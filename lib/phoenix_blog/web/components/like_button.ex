defmodule PhoenixBlog.Web.Components.LikeButton do
  @moduledoc false

  use Phoenix.Component

  attr :post_id, :integer, required: true
  attr :like_count, :integer, default: 0
  attr :liked, :boolean, default: false
  attr :current_user, :any, default: nil

  def like_button(assigns) do
    ~H"""
    <div id={"like-btn-#{@post_id}"} class="inline-flex items-center">
      <%= if @current_user do %>
        <button
          phx-click="toggle_like"
          phx-value-post_id={@post_id}
          class={[
            "inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm font-medium transition-all duration-200 cursor-pointer",
            if(@liked,
              do:
                "bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400 hover:bg-red-100 dark:hover:bg-red-900/40",
              else:
                "bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-gray-700"
            )
          ]}
        >
          <svg
            class={["size-4 transition-transform duration-200", @liked && "scale-110"]}
            viewBox="0 0 20 20"
            fill={if(@liked, do: "currentColor", else: "none")}
            stroke="currentColor"
            stroke-width="1.5"
          >
            <path d="M3.172 5.172a4 4 0 015.656 0L10 6.343l1.172-1.171a4 4 0 115.656 5.656L10 17.657l-6.828-6.829a4 4 0 010-5.656z" />
          </svg>
          {@like_count}
        </button>
      <% else %>
        <span class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm font-medium bg-gray-100 dark:bg-gray-800 text-gray-500 dark:text-gray-400">
          <svg class="size-4" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.5">
            <path d="M3.172 5.172a4 4 0 015.656 0L10 6.343l1.172-1.171a4 4 0 115.656 5.656L10 17.657l-6.828-6.829a4 4 0 010-5.656z" />
          </svg>
          {@like_count}
        </span>
      <% end %>
    </div>
    """
  end
end
