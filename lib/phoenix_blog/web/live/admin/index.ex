defmodule PhoenixBlog.Web.Live.Admin.Index do
  use PhoenixBlog.Web, :live_view

  alias PhoenixBlog.Post

  @per_page 20

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Manage Posts")
      |> assign(:page, 1)
      |> assign(:status_filter, nil)
      |> assign(:tag_filter, nil)
      |> assign(:search, "")
      |> assign(:show_deleted, false)
      |> load_posts()

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

  def handle_event("filter_status", %{"status" => status}, socket) do
    status_filter = if status == "" or status == "all", do: nil, else: status

    {:noreply,
     socket
     |> assign(:status_filter, status_filter)
     |> assign(:page, 1)
     |> load_posts()}
  end

  def handle_event("toggle_deleted", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_deleted, !socket.assigns.show_deleted)
     |> assign(:page, 1)
     |> load_posts()}
  end

  def handle_event("publish", %{"id" => id}, socket) do
    post = PhoenixBlog.get_post!(id)

    case PhoenixBlog.publish_post(post) do
      {:ok, _post} ->
        {:noreply,
         socket
         |> put_flash(:info, "Post published")
         |> load_posts()}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to publish post")}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    post = PhoenixBlog.get_post!(id)

    case PhoenixBlog.soft_delete_post(post) do
      {:ok, _post} ->
        {:noreply,
         socket
         |> put_flash(:info, "Post deleted")
         |> load_posts()}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to delete post")}
    end
  end

  def handle_event("restore", %{"id" => id}, socket) do
    post = PhoenixBlog.get_post!(id)

    case PhoenixBlog.restore_post(post) do
      {:ok, _post} ->
        {:noreply,
         socket
         |> put_flash(:info, "Post restored")
         |> load_posts()}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to restore post")}
    end
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
    opts = [
      page: socket.assigns.page,
      per_page: @per_page,
      status: socket.assigns.status_filter,
      tag: socket.assigns.tag_filter,
      search: socket.assigns.search,
      show_deleted: socket.assigns.show_deleted
    ]

    posts = PhoenixBlog.list_posts(opts)
    total_count = PhoenixBlog.count_posts(opts)
    total_pages = ceil(total_count / @per_page)

    socket
    |> assign(:total_count, total_count)
    |> assign(:total_pages, max(total_pages, 1))
    |> assign(:posts_empty?, posts == [])
    |> stream(:posts, posts, reset: true)
  end

  defp status_badge_class(status) do
    case status do
      :published -> "bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400"
      :draft -> "bg-yellow-100 dark:bg-yellow-900/30 text-yellow-700 dark:text-yellow-400"
      :archived -> "bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400"
      _ -> "bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 dark:bg-gray-950">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <%!-- Header --%>
        <div class="flex items-center justify-between mb-8">
          <div>
            <h1 class="text-2xl font-bold text-gray-900 dark:text-gray-100">Manage Posts</h1>
            <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">{@total_count} total posts</p>
          </div>
          <a
            href={"#{@dashboard_path}/new"}
            data-phx-link="redirect"
            data-phx-link-state="push"
            class="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-700 transition-colors shadow-sm"
          >
            + New Post
          </a>
        </div>

        <%!-- Filters --%>
        <div class="flex flex-wrap items-center gap-3 mb-6">
          <.form for={%{}} phx-change="search" phx-submit="search">
            <input
              type="text"
              placeholder="Search..."
              phx-debounce="300"
              name="search"
              value={@search}
              class="w-60 px-3 py-2 text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500"
            />
          </.form>

          <.form for={%{}} phx-change="filter_status" phx-submit="filter_status">
            <select
              name="status"
              class="px-3 py-2 text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500"
            >
              <option value="all" selected={is_nil(@status_filter)}>All Statuses</option>
              <option value="draft" selected={@status_filter == "draft"}>Draft</option>
              <option value="published" selected={@status_filter == "published"}>Published</option>
              <option value="archived" selected={@status_filter == "archived"}>Archived</option>
            </select>
          </.form>

          <label class="flex items-center gap-2 text-sm text-gray-900 dark:text-gray-100 cursor-pointer">
            <input
              type="checkbox"
              phx-click="toggle_deleted"
              checked={@show_deleted}
              class="rounded border-gray-300 dark:border-gray-600 text-indigo-600 focus:ring-indigo-500"
            /> Show deleted
          </label>
        </div>

        <%!-- Empty State --%>
        <div
          :if={@posts_empty?}
          class="text-center py-16 bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-700"
        >
          <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-1">No posts found</h3>
          <p class="text-gray-500 dark:text-gray-400 mb-4">
            Get started by creating your first post.
          </p>
          <a
            href={"#{@dashboard_path}/new"}
            data-phx-link="redirect"
            data-phx-link-state="push"
            class="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-700"
          >
            + New Post
          </a>
        </div>

        <%!-- Posts Table --%>
        <div
          :if={!@posts_empty?}
          class="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-700 overflow-hidden"
        >
          <table class="w-full">
            <thead class="bg-gray-50 dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700">
              <tr>
                <th class="text-left px-4 py-3 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Title
                </th>
                <th class="text-left px-4 py-3 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Status
                </th>
                <th class="text-left px-4 py-3 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Author
                </th>
                <th class="text-left px-4 py-3 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Date
                </th>
                <th class="text-right px-4 py-3 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody
              id="admin-posts"
              phx-update="stream"
              class="divide-y divide-gray-100 dark:divide-gray-800"
            >
              <tr
                :for={{id, post} <- @streams.posts}
                id={id}
                class={[
                  "hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors",
                  Post.deleted?(post) && "opacity-50"
                ]}
              >
                <td class="px-4 py-3">
                  <a
                    href={"#{@dashboard_path}/#{post.id}/edit"}
                    data-phx-link="redirect"
                    data-phx-link-state="push"
                    class="font-medium text-gray-900 dark:text-gray-100 hover:text-indigo-600 dark:hover:text-indigo-400 transition-colors"
                  >
                    {post.title}
                  </a>
                  <div class="flex gap-1 mt-1">
                    <span
                      :for={tag <- Enum.take(post.tags, 3)}
                      class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 text-gray-500 dark:text-gray-400 rounded text-xs"
                    >
                      {tag}
                    </span>
                  </div>
                </td>
                <td class="px-4 py-3">
                  <span class={[
                    "px-2 py-1 rounded-full text-xs font-medium",
                    status_badge_class(post.status)
                  ]}>
                    {post.status}
                  </span>
                  <span
                    :if={Post.deleted?(post)}
                    class="ml-1 px-2 py-1 rounded-full text-xs font-medium bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400"
                  >
                    deleted
                  </span>
                </td>
                <td class="px-4 py-3 text-sm text-gray-500 dark:text-gray-400">
                  {post.author || "—"}
                </td>
                <td class="px-4 py-3 text-sm text-gray-500 dark:text-gray-400">
                  {Calendar.strftime(post.inserted_at, "%b %d, %Y")}
                </td>
                <td class="px-4 py-3 text-right">
                  <div class="flex items-center justify-end gap-2">
                    <a
                      href={"#{@dashboard_path}/#{post.id}/edit"}
                      data-phx-link="redirect"
                      data-phx-link-state="push"
                      class="text-xs text-indigo-600 dark:text-indigo-400 hover:text-indigo-800 dark:hover:text-indigo-300 font-medium"
                    >
                      Edit
                    </a>
                    <button
                      :if={post.status != :published and !Post.deleted?(post)}
                      phx-click="publish"
                      phx-value-id={post.id}
                      data-confirm="Publish this post?"
                      class="text-xs text-green-600 dark:text-green-400 hover:text-green-800 dark:hover:text-green-300 font-medium"
                    >
                      Publish
                    </button>
                    <button
                      :if={!Post.deleted?(post)}
                      phx-click="delete"
                      phx-value-id={post.id}
                      data-confirm="Delete this post?"
                      class="text-xs text-red-600 dark:text-red-400 hover:text-red-800 dark:hover:text-red-300 font-medium"
                    >
                      Delete
                    </button>
                    <button
                      :if={Post.deleted?(post)}
                      phx-click="restore"
                      phx-value-id={post.id}
                      class="text-xs text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 font-medium"
                    >
                      Restore
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <%!-- Pagination --%>
        <div
          :if={!@posts_empty? and @total_pages > 1}
          class="flex items-center justify-center gap-4 mt-6"
        >
          <button
            phx-click="prev_page"
            disabled={@page == 1}
            class={[
              "px-4 py-2 rounded-lg text-sm font-medium border",
              if(@page == 1,
                do:
                  "opacity-50 cursor-not-allowed border-gray-200 dark:border-gray-700 text-gray-400",
                else:
                  "border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-800"
              )
            ]}
          >
            Previous
          </button>
          <span class="text-sm text-gray-500 dark:text-gray-400">Page {@page} of {@total_pages}</span>
          <button
            phx-click="next_page"
            disabled={@page >= @total_pages}
            class={[
              "px-4 py-2 rounded-lg text-sm font-medium border",
              if(@page >= @total_pages,
                do:
                  "opacity-50 cursor-not-allowed border-gray-200 dark:border-gray-700 text-gray-400",
                else:
                  "border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-800"
              )
            ]}
          >
            Next
          </button>
        </div>
      </div>
    </div>
    """
  end
end
