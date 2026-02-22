defmodule PhoenixBlog.Web.BlogComponents do
  @moduledoc """
  Components for rendering Editor.js blog content as HTML.
  """
  use Phoenix.Component
  import Phoenix.HTML, only: [raw: 1]

  @doc """
  Extracts a plain-text excerpt from a post's Editor.js body.

  Returns the first paragraph's text, stripped of HTML tags and truncated.

      iex> extract_excerpt(post)
      "This is the beginning of the post..."

      iex> extract_excerpt(post, 100)
      "Shorter excerpt..."
  """
  def extract_excerpt(post, max_length \\ 150) do
    case post.body do
      %{"blocks" => blocks} when is_list(blocks) ->
        paragraph =
          Enum.find(blocks, fn block ->
            is_map(block) and Map.get(block, "type") == "paragraph"
          end)

        case paragraph do
          %{"data" => %{"text" => text}} ->
            clean = String.replace(text, ~r/<[^>]*>/, "")

            if String.length(clean) > max_length do
              String.slice(clean, 0, max_length) <> "..."
            else
              clean
            end

          _ ->
            ""
        end

      _ ->
        ""
    end
  end

  attr :blocks, :list, required: true

  def render_editor_blocks(assigns) do
    ~H"""
    <div class="phoenix-blog-content">
      <div :for={block <- @blocks} class="mb-6">
        {render_block(block)}
      </div>
    </div>
    """
  end

  # Paragraph
  defp render_block(%{"type" => "paragraph", "data" => %{"text" => text}}) do
    assigns = %{text: text}

    ~H"""
    <p class="text-gray-700 dark:text-gray-300 leading-relaxed text-lg">
      {raw(@text)}
    </p>
    """
  end

  # Header
  defp render_block(%{"type" => "header", "data" => %{"text" => text, "level" => level}}) do
    assigns = %{text: text, level: level}

    ~H"""
    <%= case @level do %>
      <% 1 -> %>
        <h1 class="text-4xl font-bold text-gray-900 dark:text-gray-100 mt-8 mb-4">
          {raw(@text)}
        </h1>
      <% 2 -> %>
        <h2 class="text-3xl font-bold text-gray-900 dark:text-gray-100 mt-6 mb-3">
          {raw(@text)}
        </h2>
      <% 3 -> %>
        <h3 class="text-2xl font-bold text-gray-900 dark:text-gray-100 mt-6 mb-3">
          {raw(@text)}
        </h3>
      <% 4 -> %>
        <h4 class="text-xl font-semibold text-gray-900 dark:text-gray-100 mt-4 mb-2">
          {raw(@text)}
        </h4>
      <% 5 -> %>
        <h5 class="text-lg font-semibold text-gray-900 dark:text-gray-100 mt-4 mb-2">
          {raw(@text)}
        </h5>
      <% _ -> %>
        <h6 class="text-base font-semibold text-gray-900 dark:text-gray-100 mt-4 mb-2">
          {raw(@text)}
        </h6>
    <% end %>
    """
  end

  # List (v2 nested format with ordered/unordered/checklist styles, and v1 flat format)
  defp render_block(%{"type" => "list", "data" => %{"style" => style, "items" => items}})
       when is_list(items) do
    normalized = normalize_list_items(items)
    assigns = %{style: style, items: normalized}

    ~H"""
    <%= cond do %>
      <% @style == "checklist" -> %>
        <div class="my-4 space-y-2">
          <.render_checklist_items items={@items} />
        </div>
      <% @style == "ordered" -> %>
        <ol class="list-decimal list-outside ml-6 space-y-2">
          <.render_list_items items={@items} style={@style} />
        </ol>
      <% true -> %>
        <ul class="list-disc list-outside ml-6 space-y-2">
          <.render_list_items items={@items} style={@style} />
        </ul>
    <% end %>
    """
  end

  # Quote
  defp render_block(%{"type" => "quote", "data" => data}) do
    text = Map.get(data, "text", "")
    caption = Map.get(data, "caption", "")
    assigns = %{text: text, caption: caption}

    ~H"""
    <blockquote class="border-l-4 border-indigo-500 pl-6 py-4 my-6 bg-gray-50 dark:bg-gray-800/50 rounded-r-lg">
      <p class="text-lg italic text-gray-700 dark:text-gray-300 mb-2">
        {raw(@text)}
      </p>
      <cite :if={@caption != ""} class="text-sm text-gray-500 dark:text-gray-400 not-italic">
        — {@caption}
      </cite>
    </blockquote>
    """
  end

  # Code
  defp render_block(%{"type" => "code", "data" => %{"code" => code}}) do
    assigns = %{code: code}

    ~H"""
    <div class="my-6 rounded-lg overflow-hidden">
      <pre class="bg-gray-900 text-gray-100 p-4 overflow-x-auto" phx-no-curly-interpolation><code class="text-sm font-mono">{@code}</code></pre>
    </div>
    """
  end

  # Table
  defp render_block(%{"type" => "table", "data" => %{"content" => content}})
       when is_list(content) do
    assigns = %{rows: content}

    ~H"""
    <div class="overflow-x-auto my-6">
      <table class="w-full border-collapse">
        <tbody>
          <tr :for={row <- @rows} class="border-b border-gray-200 dark:border-gray-700">
            <td
              :for={cell <- row}
              class="border border-gray-200 dark:border-gray-700 px-4 py-2 text-gray-700 dark:text-gray-300"
            >
              {raw(cell)}
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  # Checklist (standalone @editorjs/checklist plugin, legacy format)
  defp render_block(%{"type" => "checklist", "data" => %{"items" => items}})
       when is_list(items) do
    normalized = normalize_list_items(items)
    assigns = %{items: normalized}

    ~H"""
    <div class="my-4 space-y-2">
      <.render_checklist_items items={@items} />
    </div>
    """
  end

  # Delimiter
  defp render_block(%{"type" => "delimiter"}) do
    assigns = %{}

    ~H"""
    <div class="flex justify-center items-center my-8">
      <div class="flex gap-2">
        <span class="w-2 h-2 rounded-full bg-gray-300 dark:bg-gray-600"></span>
        <span class="w-2 h-2 rounded-full bg-gray-300 dark:bg-gray-600"></span>
        <span class="w-2 h-2 rounded-full bg-gray-300 dark:bg-gray-600"></span>
      </div>
    </div>
    """
  end

  # Embed (YouTube, Twitter, etc.)
  defp render_block(%{"type" => "embed", "data" => data}) do
    source = Map.get(data, "source", "")
    embed = Map.get(data, "embed", "")
    service = Map.get(data, "service", "")
    assigns = %{source: source, embed: embed, service: service}

    ~H"""
    <div class="my-8">
      <%= cond do %>
        <% @service == "youtube" or String.contains?(@source, "youtube.com") or String.contains?(@source, "youtu.be") -> %>
          <div class="aspect-video">
            <iframe
              src={@embed}
              frameborder="0"
              allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
              allowfullscreen
              class="w-full h-full rounded-lg shadow-lg"
            >
            </iframe>
          </div>
        <% @service == "twitter" or String.contains?(@source, "twitter.com") or String.contains?(@source, "x.com") -> %>
          <div class="flex justify-center">
            <blockquote class="twitter-tweet">
              <a href={@source}>View Tweet</a>
            </blockquote>
          </div>
        <% @service == "vimeo" or String.contains?(@source, "vimeo.com") -> %>
          <div class="aspect-video">
            <iframe
              src={@embed}
              frameborder="0"
              allow="autoplay; fullscreen; picture-in-picture"
              allowfullscreen
              class="w-full h-full rounded-lg shadow-lg"
            >
            </iframe>
          </div>
        <% true -> %>
          <div class="p-4 bg-gray-100 dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700">
            <p class="text-sm text-gray-600 dark:text-gray-400">
              Embedded content:
              <a
                href={@source}
                target="_blank"
                rel="noopener noreferrer"
                class="text-indigo-600 dark:text-indigo-400 underline"
              >
                {@source}
              </a>
            </p>
          </div>
      <% end %>
    </div>
    """
  end

  # Image
  defp render_block(%{"type" => "image", "data" => data}) do
    url = Map.get(data, "url", "")
    caption = Map.get(data, "caption", "")
    assigns = %{url: url, caption: caption}

    ~H"""
    <figure class="my-8">
      <img src={@url} alt={@caption} class="w-full rounded-lg shadow-lg" />
      <figcaption
        :if={@caption != ""}
        class="text-center text-sm text-gray-500 dark:text-gray-400 mt-2"
      >
        {@caption}
      </figcaption>
    </figure>
    """
  end

  # Fallback
  defp render_block(block) do
    assigns = %{block: block}

    ~H"""
    <div class="my-4 p-3 bg-yellow-50 dark:bg-yellow-900/30 border border-yellow-200 dark:border-yellow-800 rounded-lg text-sm text-yellow-800 dark:text-yellow-300">
      Unsupported block type: {Map.get(@block, "type", "unknown")}
    </div>
    """
  end

  # List helper components

  defp render_list_items(assigns) do
    ~H"""
    <li :for={item <- @items} class="text-gray-700 dark:text-gray-300 text-lg pl-2">
      {raw(item.content)}
      <%= if item.children != [] do %>
        <%= if @style == "ordered" do %>
          <ol class="list-decimal list-outside ml-6 space-y-1 mt-1">
            <.render_list_items items={item.children} style={@style} />
          </ol>
        <% else %>
          <ul class="list-disc list-outside ml-6 space-y-1 mt-1">
            <.render_list_items items={item.children} style={@style} />
          </ul>
        <% end %>
      <% end %>
    </li>
    """
  end

  defp render_checklist_items(assigns) do
    ~H"""
    <%= for item <- @items do %>
      <div class="flex items-start gap-3">
        <div class={[
          "mt-1 flex-shrink-0 w-5 h-5 rounded border-2 flex items-center justify-center",
          if(item.checked,
            do: "bg-indigo-500 border-indigo-500",
            else: "border-gray-300 dark:border-gray-600"
          )
        ]}>
          <svg
            :if={item.checked}
            class="w-3 h-3 text-white"
            fill="none"
            viewBox="0 0 24 24"
            stroke-width="3"
            stroke="currentColor"
          >
            <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
          </svg>
        </div>
        <div>
          <span class={[
            "text-lg leading-relaxed",
            if(item.checked,
              do: "text-gray-400 dark:text-gray-500 line-through",
              else: "text-gray-700 dark:text-gray-300"
            )
          ]}>
            {raw(item.content)}
          </span>
          <div :if={item.children != []} class="mt-1 ml-2 space-y-2">
            <.render_checklist_items items={item.children} />
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  # Normalizes list items from v1 (flat strings) or v2 (nested objects) format
  defp normalize_list_items(items) do
    Enum.map(items, fn
      item when is_binary(item) ->
        %{content: item, checked: false, children: []}

      %{"content" => content} = item ->
        checked = get_in(item, ["meta", "checked"]) == true
        children = normalize_list_items(Map.get(item, "items", []))
        %{content: content, checked: checked, children: children}

      %{"text" => text} = item ->
        %{content: text, checked: Map.get(item, "checked", false), children: []}

      _ ->
        %{content: "", checked: false, children: []}
    end)
  end
end
