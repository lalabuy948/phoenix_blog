defmodule PhoenixBlog.Web.Live.Admin.Form do
  use PhoenixBlog.Web, :live_view

  alias PhoenixBlog.Post

  @impl true
  def mount(params, _session, socket) do
    {action, post} =
      case Map.get(params, "id") do
        nil ->
          {:new, %Post{tags: [], body: %{"blocks" => []}}}

        id ->
          {:edit, PhoenixBlog.get_post!(id)}
      end

    tags_input = Enum.join(post.tags, ", ")

    {:ok,
     socket
     |> assign(:page_title, if(action == :new, do: "New Post", else: "Edit Post"))
     |> assign(:action, action)
     |> assign(:post, post)
     |> assign(:tags_input, tags_input)
     |> assign(:body_json, post.body)
     |> assign(:last_saved_at, nil)
     |> assign_form(PhoenixBlog.change_post(post))}
  end

  @impl true
  def handle_event("validate", %{"post" => post_params}, socket) do
    new_tags_input = Map.get(post_params, "tags_input", socket.assigns.tags_input)
    post_params = process_form_params(post_params, new_tags_input)

    post_params =
      if Map.get(post_params, "slug", "") == "" and Map.get(post_params, "title", "") != "" do
        slug = Post.slugify(post_params["title"])
        Map.put(post_params, "slug", slug)
      else
        post_params
      end

    changeset = PhoenixBlog.change_post(socket.assigns.post, post_params)

    socket =
      if socket.assigns.action == :new and
           post_params["title"] != "" and
           String.length(post_params["title"] || "") > 2 do
        auto_save_new_post(socket, post_params, new_tags_input)
      else
        if socket.assigns.action == :edit do
          auto_save_existing_post(socket, post_params)
        else
          socket
        end
        |> assign(:tags_input, new_tags_input)
        |> assign_form(Map.put(changeset, :action, :validate))
      end

    {:noreply, socket}
  end

  def handle_event("save", %{"post" => post_params}, socket) do
    save_post(socket, socket.assigns.action, post_params)
  end

  @impl true
  def handle_event("regenerate_slug", %{"title" => title}, socket) do
    slug = Post.slugify(title)

    # Collect current form params and merge the new slug
    current_params =
      case socket.assigns.form.source do
        %Ecto.Changeset{} = cs ->
          cs.changes
          |> Enum.into(%{}, fn {k, v} -> {Atom.to_string(k), v} end)

        _ ->
          %{}
      end

    post_params =
      current_params
      |> Map.put("title", title)
      |> Map.put("slug", slug)

    changeset =
      PhoenixBlog.change_post(socket.assigns.post, post_params)
      |> Map.put(:action, :validate)

    socket = assign_form(socket, changeset)

    socket =
      if socket.assigns.action == :edit do
        case PhoenixBlog.update_post(socket.assigns.post, %{"slug" => slug}) do
          {:ok, post} ->
            socket
            |> assign(:post, post)
            |> assign(:last_saved_at, DateTime.utc_now())

          {:error, error_changeset} ->
            assign_form(socket, Map.put(error_changeset, :action, :validate))
        end
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("editor_change", %{"body" => body}, socket) do
    socket =
      if socket.assigns.action == :edit do
        auto_save_editor_content(socket, body)
      else
        socket
      end
      |> assign(:body_json, body)

    {:noreply, socket}
  end

  defp auto_save_new_post(socket, post_params, tags_input) do
    post_params =
      post_params
      |> Map.put("body", socket.assigns.body_json)
      |> Map.put("status", "draft")

    case PhoenixBlog.create_post(post_params) do
      {:ok, post} ->
        socket
        |> assign(:action, :edit)
        |> assign(:post, post)
        |> assign(:page_title, "Edit Post")
        |> assign(:last_saved_at, DateTime.utc_now())
        |> assign(:tags_input, tags_input)
        |> assign_form(PhoenixBlog.change_post(post, post_params) |> Map.put(:action, :validate))
        |> push_event("update-url", %{url: "#{socket.assigns.dashboard_path}/#{post.id}/edit"})

      {:error, _changeset} ->
        socket
        |> assign(:tags_input, tags_input)
    end
  end

  defp auto_save_existing_post(socket, post_params) do
    post_params = Map.put(post_params, "body", socket.assigns.body_json)

    case PhoenixBlog.update_post(socket.assigns.post, post_params) do
      {:ok, post} ->
        socket
        |> assign(:post, post)
        |> assign(:last_saved_at, DateTime.utc_now())

      {:error, _changeset} ->
        socket
    end
  end

  defp auto_save_editor_content(socket, body) do
    case PhoenixBlog.update_post(socket.assigns.post, %{"body" => body}) do
      {:ok, post} ->
        socket
        |> assign(:post, post)
        |> assign(:last_saved_at, DateTime.utc_now())

      {:error, _changeset} ->
        socket
    end
  end

  defp save_post(socket, action, post_params) do
    tags_input = Map.get(post_params, "tags_input", socket.assigns.tags_input)
    post_params = process_form_params(post_params, tags_input)
    post_params = Map.put(post_params, "body", socket.assigns.body_json)

    result =
      case action do
        :new -> PhoenixBlog.create_post(post_params)
        :edit -> PhoenixBlog.update_post(socket.assigns.post, post_params)
      end

    case result do
      {:ok, post} ->
        message =
          if action == :new, do: "Post created successfully", else: "Post saved successfully"

        socket =
          socket
          |> assign(:post, post)
          |> assign(:last_saved_at, DateTime.utc_now())
          |> put_flash(:info, message)

        socket =
          if action == :new do
            socket
            |> assign(:action, :edit)
            |> assign(:page_title, "Edit Post")
            |> push_event("update-url", %{
              url: "#{socket.assigns.dashboard_path}/#{post.id}/edit"
            })
          else
            socket
          end

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp process_form_params(post_params, tags_input) do
    tags =
      tags_input
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.map(&String.downcase/1)
      |> Enum.uniq()

    post_params
    |> Map.put("tags", tags)
    |> Map.delete("tags_input")
  end

  defp format_time_ago(datetime) do
    seconds_ago = DateTime.diff(DateTime.utc_now(), datetime, :second)

    cond do
      seconds_ago < 60 -> "just now"
      seconds_ago < 3600 -> "#{div(seconds_ago, 60)} min ago"
      seconds_ago < 86400 -> "#{div(seconds_ago, 3600)}h ago"
      true -> "#{div(seconds_ago, 86400)}d ago"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-100 dark:bg-gray-950">
      <%!-- Sticky top bar --%>
      <div class="bg-white dark:bg-gray-900 border-b border-gray-200 dark:border-gray-700 sticky top-0 z-10">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex items-center justify-between h-14">
            <div class="flex items-center gap-3">
              <a
                href={@dashboard_path}
                data-phx-link="redirect"
                data-phx-link-state="push"
                class="inline-flex items-center gap-1.5 text-sm font-medium text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100 transition-colors"
              >
                <.icon name="hero-arrow-left-mini" class="size-4" /> Posts
              </a>
              <span class="text-gray-300 dark:text-gray-600">|</span>
              <h1 class="text-sm font-semibold text-gray-900 dark:text-gray-100 truncate max-w-xs">
                {if @action == :new, do: "New Post", else: @post.title}
              </h1>
            </div>

            <div class="flex items-center gap-3">
              <div
                :if={@last_saved_at}
                class="flex items-center gap-1.5 text-xs text-gray-500 dark:text-gray-400"
              >
                <span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                Saved {format_time_ago(@last_saved_at)}
              </div>
              <span
                :if={!@last_saved_at && @action == :new}
                class="text-xs text-amber-600 dark:text-amber-400 font-medium"
              >
                Unsaved draft
              </span>
            </div>
          </div>
        </div>
      </div>

      <.form
        for={@form}
        id="post-form"
        phx-change="validate"
        phx-submit="save"
        phx-hook="PhoenixBlogUrlUpdate"
      >
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div class="grid grid-cols-1 lg:grid-cols-12 gap-6">
            <%!-- Main content area --%>
            <div class="lg:col-span-8 space-y-5">
              <%!-- Title --%>
              <div class="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm p-6">
                <.input
                  field={@form[:title]}
                  type="text"
                  label="Title"
                  required
                  phx-debounce="300"
                  placeholder="Your article title..."
                  class="w-full text-xl font-semibold rounded-lg border border-gray-300 dark:border-gray-600 px-4 py-3 text-gray-900 dark:text-gray-100 bg-white dark:bg-gray-800 shadow-sm placeholder:text-gray-400 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
                />
              </div>

              <%!-- Editor --%>
              <div class="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm">
                <div class="px-6 py-3 border-b border-gray-100 dark:border-gray-800 bg-gray-50/60 dark:bg-gray-800/60">
                  <span class="text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400">
                    Content
                  </span>
                </div>
                <div
                  id="phoenix-blog-editor"
                  phx-hook="PhoenixBlogEditor"
                  phx-update="ignore"
                  data-content={Jason.encode!(@post.body)}
                  class="min-h-[560px] px-6 py-4"
                >
                </div>
              </div>
            </div>

            <%!-- Sidebar --%>
            <div class="lg:col-span-4 space-y-5">
              <div class="sticky top-[72px] space-y-5">
                <%!-- Actions --%>
                <div class="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm p-5">
                  <div class="flex flex-col gap-2.5">
                    <button
                      type="submit"
                      class="w-full px-4 py-2.5 bg-gray-900 dark:bg-gray-100 text-white dark:text-gray-900 text-sm font-semibold rounded-lg hover:bg-gray-800 dark:hover:bg-gray-200 active:bg-gray-950 transition-colors shadow-sm"
                      phx-disable-with="Saving..."
                    >
                      {if @action == :new, do: "Create Post", else: "Save Changes"}
                    </button>
                    <a
                      href={@dashboard_path}
                      data-phx-link="redirect"
                      data-phx-link-state="push"
                      class="w-full px-4 py-2.5 text-center text-sm font-medium text-gray-700 dark:text-gray-300 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors"
                    >
                      Discard
                    </a>
                  </div>
                </div>

                <%!-- Publishing --%>
                <div class="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm">
                  <div class="px-5 py-3 border-b border-gray-100 dark:border-gray-800">
                    <h3 class="text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400">
                      Publishing
                    </h3>
                  </div>
                  <div class="p-5 space-y-4">
                    <.input
                      field={@form[:status]}
                      type="select"
                      label="Status"
                      options={[
                        {"Draft", :draft},
                        {"Published", :published},
                        {"Archived", :archived}
                      ]}
                      required
                    />
                    <div>
                      <div class="flex items-end gap-2">
                        <div class="flex-1">
                          <.input
                            field={@form[:slug]}
                            type="text"
                            label="URL Slug"
                            required
                            placeholder="my-blog-post"
                          />
                        </div>
                        <button
                          type="button"
                          id="regenerate-slug-btn"
                          phx-hook="PhoenixBlogRegenerateSlug"
                          title="Regenerate slug from title"
                          class="mb-[2px] inline-flex items-center justify-center size-9 rounded-lg border border-gray-300 dark:border-gray-600 bg-gray-50 dark:bg-gray-800 text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 hover:text-gray-700 dark:hover:text-gray-200 transition-colors shrink-0"
                        >
                          <.icon name="hero-arrow-path-mini" class="size-4" />
                        </button>
                      </div>
                    </div>
                    <.input
                      field={@form[:author]}
                      type="text"
                      label="Author"
                      placeholder="John Doe"
                      phx-debounce="300"
                    />
                    <.input
                      field={@form[:published_at]}
                      type="datetime-local"
                      label="Publish Date"
                      phx-debounce="300"
                    />
                  </div>
                </div>

                <%!-- SEO & Metadata --%>
                <div class="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm">
                  <div class="px-5 py-3 border-b border-gray-100 dark:border-gray-800">
                    <h3 class="text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400">
                      SEO &amp; Metadata
                    </h3>
                  </div>
                  <div class="p-5 space-y-4">
                    <.input
                      field={@form[:seo_description]}
                      type="textarea"
                      label="Meta Description"
                      placeholder="Brief description for search engines..."
                      phx-debounce="300"
                      rows="3"
                    />
                    <div>
                      <.input
                        field={@form[:tags_input]}
                        type="text"
                        label="Tags"
                        placeholder="elixir, phoenix, tutorial"
                        value={@tags_input}
                        phx-debounce="300"
                      />
                      <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">Comma-separated</p>
                    </div>
                  </div>
                </div>

                <%!-- Featured Image --%>
                <div class="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm">
                  <div class="px-5 py-3 border-b border-gray-100 dark:border-gray-800">
                    <h3 class="text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400">
                      Featured Image
                    </h3>
                  </div>
                  <div class="p-5">
                    <.input
                      field={@form[:featured_image_url]}
                      type="text"
                      label="Image URL"
                      placeholder="https://example.com/image.jpg"
                    />
                    <div
                      :if={@form[:featured_image_url].value && @form[:featured_image_url].value != ""}
                      class="mt-3"
                    >
                      <img
                        src={@form[:featured_image_url].value}
                        alt="Preview"
                        class="w-full h-32 object-cover rounded-lg border border-gray-200 dark:border-gray-700"
                        onerror="this.style.display='none'"
                      />
                    </div>
                    <div
                      :if={
                        !@form[:featured_image_url].value || @form[:featured_image_url].value == ""
                      }
                      class="mt-3 flex items-center justify-center h-24 rounded-lg border-2 border-dashed border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800"
                    >
                      <span class="text-xs text-gray-400 dark:text-gray-500">No image set</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </.form>
    </div>
    """
  end
end
