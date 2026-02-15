# PhoenixBlog

![](github/blog_page_search.png)

Plug-and-play blog engine for Phoenix with [Editor.js](https://editorjs.io/) integration.

- Public blog with search, tag filtering, and pagination
- Admin dashboard with Editor.js rich text editor
- Auto-save drafts — posts save automatically as you type
- Embeddable recent posts component for any page
- Self-contained CSS and JS — loads its own assets automatically
- Supports PostgreSQL, MySQL, and SQLite
- Authentication via host app's `on_mount` hooks

![editorjs screenshot](github/editorjs.png)

## Installation

Add `phoenix_blog` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:phoenix_blog, "~> 0.1"}
  ]
end
```

## Setup

### 1. Configure the repo

```elixir
# config/config.exs
config :phoenix_blog, repo: MyApp.Repo
```

### 2. Create and run the migration

```bash
mix ecto.gen.migration add_phoenix_blog
```

```elixir
defmodule MyApp.Repo.Migrations.AddPhoenixBlog do
  use Ecto.Migration

  def up, do: PhoenixBlog.Migration.up()
  def down, do: PhoenixBlog.Migration.down()
end
```

```bash
mix ecto.migrate
```

### 3. Serve static assets

Add to your `endpoint.ex`, **before** the existing `Plug.Static`:

```elixir
plug Plug.Static,
  at: "/phoenix_blog",
  from: {:phoenix_blog, "priv/static"}
```

### 4. Register the JS hooks

In your `assets/js/app.js`:

```javascript
import { PhoenixBlogHooks } from "../../deps/phoenix_blog/priv/static/editorjs/hook.js"

const liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: { ...PhoenixBlogHooks, ...yourOtherHooks }
})
```

Editor.js scripts are loaded dynamically by the hook — no additional `<script>` tags needed.

### 5. Add Tailwind source

Add the library's templates to your Tailwind source paths so its utility classes get generated. In `assets/css/app.css`:

```css
@source "../../deps/phoenix_blog/lib";
```

### 6. Mount routes

In your `router.ex`:

```elixir
use PhoenixBlog.Web, :router

# Public blog (accessible to everyone)
scope "/" do
  pipe_through :browser
  phoenix_blog "/blog"
end

# Admin dashboard (protected by your auth)
scope "/" do
  pipe_through [:browser, :require_authenticated_user]
  phoenix_blog_dashboard "/admin/blog",
    on_mount: [{MyAppWeb.UserAuth, :require_authenticated}]
end
```

That's it. The library loads its own CSS (`/phoenix_blog/app.css`) and renders inside your app's root layout automatically.

## Embedding Recent Posts

Show the latest blog posts on any LiveView page using the included component:

```elixir
<.live_component
  module={PhoenixBlog.Web.Components.RecentPosts}
  id="recent-posts"
  blog_path="/blog"
/>
```

![recent posts](github/embed_posts.png)


| Attribute | Default | Description |
|-----------|---------|-------------|
| `blog_path` | **(required)** | Path where your blog is mounted |
| `count` | `3` | Number of posts to display |
| `title` | `"Latest Posts"` | Section heading (`nil` to hide) |
| `class` | `nil` | Additional CSS classes on the wrapper |

## Configuration

| Option | Default | Description |
|--------|---------|-------------|
| `:repo` | **(required)** | Your Ecto repo module |
| `:table_name` | `"phoenix_blog_posts"` | Database table name |

## Router Options

### `phoenix_blog/2`

| Option | Default | Description |
|--------|---------|-------------|
| `:on_mount` | `[]` | Additional `on_mount` hooks |
| `:as` | `:phoenix_blog` | Live session name |
| `:layout` | `nil` | Custom app layout `{Module, :function}` |

### `phoenix_blog_dashboard/2`

| Option | Default | Description |
|--------|---------|-------------|
| `:on_mount` | `[]` | Authentication hooks (recommended) |
| `:as` | `:phoenix_blog_dashboard` | Live session name |
| `:layout` | `nil` | Custom app layout `{Module, :function}` |

## Features

### Public Blog (`/blog`)

- Responsive card grid with featured images
- Full-text search
- Tag filtering
- Pagination
- SEO-friendly slugs

### Admin Dashboard (`/admin/blog`)

- Post list with search, status filter, and pagination
- Editor.js rich text editor with auto-save
- Draft/Published/Archived status management
- SEO metadata (description, slug, tags)
- Featured image support (via URL)
- Soft delete and restore

### Editor.js Tools

The following tools are included out of the box:

- **Header** (h1-h6)
- **List** (ordered/unordered)
- **Quote** (with caption)
- **Code** (code blocks)
- **Table** (rows/cols)
- **Delimiter** (section break)
- **Embed** (YouTube, Twitter, Vimeo, Instagram, CodePen)
- **Image** (via URL)

## Public API

The `PhoenixBlog` module exposes functions for querying posts from your own code:

```elixir
# Latest published posts (for widgets, feeds, etc.)
PhoenixBlog.list_latest_published_posts(5)

# Paginated published posts with filters
PhoenixBlog.list_published_posts(page: 1, per_page: 10, tag: "elixir")

# Single post by slug
PhoenixBlog.get_post_by_slug!("my-post")

# Admin CRUD
PhoenixBlog.create_post(%{"title" => "Hello", "status" => "draft", ...})
PhoenixBlog.update_post(post, %{"status" => "published"})
PhoenixBlog.publish_post(post)
PhoenixBlog.soft_delete_post(post)
PhoenixBlog.restore_post(post)
```
