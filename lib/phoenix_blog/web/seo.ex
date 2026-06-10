defmodule PhoenixBlog.Web.SEO do
  @moduledoc """
  SEO helpers for PhoenixBlog.

  Automatically generates Open Graph tags, Twitter Card tags, canonical URLs,
  and JSON-LD structured data for blog pages. Used internally by the default
  LiveViews.

  ## Setup

  Add these two lines to the `<head>` in your root layout:

      <PhoenixBlog.Web.SEO.meta_tags seo={assigns[:seo]} />
      <PhoenixBlog.Web.SEO.json_ld seo={assigns[:seo]} />

  These are no-ops on non-blog pages (when `@seo` is nil), so they are safe to
  include in your app's global root layout.
  """

  use Phoenix.Component

  alias PhoenixBlog.Config
  alias PhoenixBlog.Web.BlogComponents

  @doc """
  Assigns SEO metadata to the socket.

  For the blog index page:

      PhoenixBlog.Web.SEO.assign_seo(socket, :index, uri)

  For a blog post page:

      PhoenixBlog.Web.SEO.assign_seo(socket, post, uri)
  """
  def assign_seo(socket, :index, uri) do
    Phoenix.Component.assign(socket, :seo, build_index_meta(uri))
  end

  def assign_seo(socket, %PhoenixBlog.Post{} = post, uri) do
    Phoenix.Component.assign(socket, :seo, build_post_meta(post, uri))
  end

  attr :seo, :map, default: nil

  def meta_tags(assigns) do
    ~H"""
    <%= if @seo do %>
      <meta name="description" content={@seo[:description]} />
      <link rel="canonical" href={@seo[:canonical_url]} />

      <%!-- Open Graph --%>
      <meta property="og:title" content={@seo[:title]} />
      <meta property="og:description" content={@seo[:description]} />
      <meta property="og:url" content={@seo[:canonical_url]} />
      <meta property="og:type" content={@seo[:og_type]} />
      <meta property="og:site_name" content={@seo[:site_name]} />
      <meta property="og:locale" content={@seo[:locale]} />
      <meta :if={@seo[:og_image]} property="og:image" content={@seo[:og_image]} />

      <%!-- Article-specific OG tags --%>
      <meta
        :if={@seo[:published_at]}
        property="article:published_time"
        content={format_datetime(@seo[:published_at])}
      />
      <meta
        :if={@seo[:modified_at]}
        property="article:modified_time"
        content={format_datetime(@seo[:modified_at])}
      />
      <meta :if={@seo[:author]} property="article:author" content={@seo[:author]} />
      <%= if @seo[:tags] do %>
        <meta :for={tag <- @seo[:tags]} property="article:tag" content={tag} />
      <% end %>

      <%!-- Twitter Card --%>
      <meta name="twitter:card" content={@seo[:twitter_card]} />
      <meta name="twitter:title" content={@seo[:title]} />
      <meta name="twitter:description" content={@seo[:description]} />
      <meta :if={@seo[:og_image]} name="twitter:image" content={@seo[:og_image]} />
      <meta :if={@seo[:twitter_site]} name="twitter:site" content={@seo[:twitter_site]} />
    <% end %>
    """
  end

  attr :seo, :map, default: nil

  def json_ld(assigns) do
    ~H"""
    <%= if @seo && @seo[:json_ld] do %>
      <script type="application/ld+json">
        {raw(Jason.encode!(@seo[:json_ld]))}
      </script>
    <% end %>
    """
  end

  # Private helpers

  defp build_index_meta(uri) do
    canonical = canonical_url(uri)
    site_name = Config.site_name()

    %{
      title: site_name,
      description: "#{site_name} - Latest articles and posts",
      canonical_url: canonical,
      og_type: "website",
      og_image: absolute_url(Config.default_og_image(), uri),
      site_name: site_name,
      locale: Config.locale(),
      twitter_card: if(Config.default_og_image(), do: "summary_large_image", else: "summary"),
      twitter_site: Config.twitter_site(),
      author: nil,
      published_at: nil,
      modified_at: nil,
      tags: nil,
      json_ld: %{
        "@context" => "https://schema.org",
        "@type" => "Blog",
        "name" => site_name,
        "url" => canonical
      }
    }
  end

  defp build_post_meta(post, uri) do
    canonical = canonical_url(uri)
    site_name = Config.site_name()
    description = post_description(post)
    image = absolute_url(post.featured_image_url || Config.default_og_image(), uri)

    %{
      title: post.title,
      description: description,
      canonical_url: canonical,
      og_type: "article",
      og_image: image,
      site_name: site_name,
      locale: Config.locale(),
      twitter_card: if(image, do: "summary_large_image", else: "summary"),
      twitter_site: Config.twitter_site(),
      author: post.author,
      published_at: post.published_at,
      modified_at: post.updated_at,
      tags: post.tags,
      json_ld: build_article_json_ld(post, canonical, site_name, description, image)
    }
  end

  defp build_article_json_ld(post, canonical, site_name, description, image) do
    json = %{
      "@context" => "https://schema.org",
      "@type" => "Article",
      "headline" => post.title,
      "description" => description,
      "url" => canonical,
      "mainEntityOfPage" => %{"@type" => "WebPage", "@id" => canonical},
      "publisher" => %{"@type" => "Organization", "name" => site_name}
    }

    json =
      if post.author do
        Map.put(json, "author", %{"@type" => "Person", "name" => post.author})
      else
        json
      end

    json =
      if post.published_at do
        Map.put(json, "datePublished", DateTime.to_iso8601(post.published_at))
      else
        json
      end

    json =
      if post.updated_at do
        Map.put(json, "dateModified", DateTime.to_iso8601(post.updated_at))
      else
        json
      end

    json =
      if image do
        Map.put(json, "image", image)
      else
        json
      end

    if post.tags && post.tags != [] do
      Map.put(json, "keywords", Enum.join(post.tags, ", "))
    else
      json
    end
  end

  defp post_description(post) do
    cond do
      post.seo_description && post.seo_description != "" ->
        post.seo_description

      true ->
        BlogComponents.extract_excerpt(post, 160)
    end
  end

  defp canonical_url(uri) when is_binary(uri) do
    parsed = URI.parse(uri)
    URI.to_string(%{parsed | query: nil, fragment: nil})
  end

  # Open Graph and Twitter Card images must be absolute URLs (with scheme and
  # host), otherwise crawlers like Telegram/WhatsApp cannot fetch the preview.
  # Resolve relative image paths against the current request URI.
  defp absolute_url(nil, _uri), do: nil

  defp absolute_url(image, uri) when is_binary(image) and is_binary(uri) do
    case URI.parse(image) do
      %URI{scheme: scheme} when is_binary(scheme) -> image
      _ -> uri |> URI.merge(image) |> URI.to_string()
    end
  end

  defp absolute_url(image, _uri), do: image

  defp format_datetime(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp format_datetime(_), do: nil
end
