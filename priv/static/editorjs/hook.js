/**
 * PhoenixBlog Editor.js hooks for Phoenix LiveView.
 *
 * Usage (ES module import):
 *   import { PhoenixBlogHooks } from "../../deps/phoenix_blog/priv/static/editorjs/hook.js"
 *   const liveSocket = new LiveSocket("/live", Socket, {
 *     hooks: { ...PhoenixBlogHooks, ...otherHooks }
 *   })
 *
 * Usage (script tag):
 *   <script src="/phoenix_blog/editorjs/hook.js"></script>
 *   // window.PhoenixBlogHooks is now available
 */

const EDITORJS_SCRIPTS = [
  "/phoenix_blog/editorjs/editorjs-core.js",
  "/phoenix_blog/editorjs/editorjs-header.js",
  "/phoenix_blog/editorjs/editorjs-list.js",
  "/phoenix_blog/editorjs/editorjs-quote.js",
  "/phoenix_blog/editorjs/editorjs-code.js",
  "/phoenix_blog/editorjs/editorjs-table.js",
  "/phoenix_blog/editorjs/editorjs-delimiter.js",
  "/phoenix_blog/editorjs/editorjs-embed.js",
  "/phoenix_blog/editorjs/editorjs-simple-image.js",
]

function loadScript(src) {
  return new Promise((resolve, reject) => {
    // Skip if already loaded
    if (document.querySelector(`script[src="${src}"]`)) {
      resolve()
      return
    }
    const script = document.createElement("script")
    script.src = src
    script.onload = resolve
    script.onerror = reject
    document.head.appendChild(script)
  })
}

async function loadEditorScripts() {
  if (window.EditorJS) return
  for (const src of EDITORJS_SCRIPTS) {
    await loadScript(src)
  }
}

// Shared color parser — handles rgb(), rgba(), space-separated, oklch, hsl, etc.
function parseColor(str) {
  if (!str || str === "transparent") return null
  // comma-separated: rgb(r, g, b) / rgba(r, g, b, a)
  let m = str.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*([\d.]+))?\)/)
  if (m) return { r: +m[1], g: +m[2], b: +m[3], a: m[4] != null ? +m[4] : 1 }
  // space-separated: rgb(r g b) / rgb(r g b / a)
  m = str.match(/rgba?\(([\d.]+)\s+([\d.]+)\s+([\d.]+)(?:\s*\/\s*([\d.]+))?\)/)
  if (m) return { r: +m[1], g: +m[2], b: +m[3], a: m[4] != null ? +m[4] : 1 }
  // oklch / hsl / color() — canvas fallback
  try {
    const c = document.createElement("canvas")
    c.width = c.height = 1
    const ctx = c.getContext("2d")
    ctx.fillStyle = str
    ctx.fillRect(0, 0, 1, 1)
    const [r, g, b, a] = ctx.getImageData(0, 0, 1, 1).data
    return { r, g, b, a: a / 255 }
  } catch { return null }
}

// Shared: detect whether the element sits on a dark background
function detectDarkBackground(el) {
  let node = el.parentElement
  while (node) {
    const bg = getComputedStyle(node).backgroundColor
    const rgba = parseColor(bg)
    if (rgba && rgba.a > 0.5) {
      const luminance = (0.299 * rgba.r + 0.587 * rgba.g + 0.114 * rgba.b) / 255
      return luminance < 0.5
    }
    node = node.parentElement
  }
  // Fallback: check media query and DOM hints
  return window.matchMedia("(prefers-color-scheme: dark)").matches
    || document.documentElement.classList.contains("dark")
    || document.body?.classList.contains("dark")
    || document.documentElement.getAttribute("data-theme") === "dark"
}

const PhoenixBlogEditor = {
  async mounted() {
    // Detect after styles have settled
    requestAnimationFrame(() => this._detectTheme())
    this._watchTheme()

    try {
      await loadEditorScripts()
      this.initEditor()
      // Re-detect after editor DOM is created
      requestAnimationFrame(() => this._detectTheme())
    } catch (error) {
      console.error("PhoenixBlog: Failed to load Editor.js scripts:", error)
    }
  },

  _detectTheme() {
    this._applyTheme(detectDarkBackground(this.el))
  },

  _applyTheme(isDark) {
    this.el.style.setProperty("--phxblog-text", isDark ? "#f3f4f6" : "#111827")
    this.el.style.setProperty("--phxblog-muted", isDark ? "#9ca3af" : "#6b7280")
    this.el.style.setProperty("--phxblog-placeholder", isDark ? "#6b7280" : "#9ca3af")
    this.el.style.setProperty("--phxblog-bg", isDark ? "#1f2937" : "#ffffff")
    this.el.style.setProperty("--phxblog-bg-hover", isDark ? "#374151" : "#f3f4f6")
    this.el.style.setProperty("--phxblog-border", isDark ? "#374151" : "#e5e7eb")
    this.el.style.setProperty("--phxblog-input-bg", isDark ? "#111827" : "#f9fafb")
  },

  _watchTheme() {
    this._mql = window.matchMedia("(prefers-color-scheme: dark)")
    this._onThemeChange = () => {
      requestAnimationFrame(() => this._detectTheme())
    }
    this._mql.addEventListener("change", this._onThemeChange)
  },

  initEditor() {
    const EditorJSCore = window.EditorJS
    const Header = window.Header
    const EditorjsList = window.EditorjsList
    const Quote = window.Quote
    const CodeTool = window.CodeTool
    const Table = window.Table
    const Delimiter = window.Delimiter
    const Embed = window.Embed
    const SimpleImage = window.SimpleImage

    if (!EditorJSCore) {
      console.error("PhoenixBlog: EditorJS not loaded")
      return
    }

    let existingData
    try {
      existingData = this.el.dataset.content
        ? JSON.parse(this.el.dataset.content)
        : { blocks: [] }
    } catch (error) {
      console.error("PhoenixBlog: Failed to parse editor content:", error)
      existingData = { blocks: [] }
    }

    try {
      this.editor = new EditorJSCore({
        holder: this.el,
        tools: {
          header: Header ? {
            class: Header,
            inlineToolbar: true,
            config: {
              placeholder: "Enter a header",
              levels: [1, 2, 3, 4, 5, 6],
              defaultLevel: 2,
            },
          } : undefined,
          list: EditorjsList ? {
            class: EditorjsList,
            inlineToolbar: true,
            config: {
              defaultStyle: "unordered",
            },
          } : undefined,
          quote: Quote ? {
            class: Quote,
            inlineToolbar: true,
            config: {
              quotePlaceholder: "Enter a quote",
              captionPlaceholder: "Quote's author",
            },
          } : undefined,
          code: CodeTool ? {
            class: CodeTool,
            config: {
              placeholder: "Enter code",
            },
          } : undefined,
          table: Table ? {
            class: Table,
            inlineToolbar: true,
            config: {
              rows: 2,
              cols: 2,
            },
          } : undefined,
          delimiter: Delimiter ? {
            class: Delimiter,
          } : undefined,
          embed: Embed ? {
            class: Embed,
            config: {
              services: {
                youtube: true,
                twitter: true,
                vimeo: true,
                instagram: true,
                codepen: true,
              },
            },
          } : undefined,
          image: SimpleImage ? {
            class: SimpleImage,
            config: {
              placeholder: "Paste image URL...",
            },
          } : undefined,
        },
        data: existingData,
        onChange: async () => {
          try {
            const data = await this.editor.save()
            this.pushEvent("editor_change", { body: data })
          } catch (error) {
            console.error("PhoenixBlog: Editor save failed:", error)
          }
        },
        placeholder: "Start writing your article...",
        autofocus: false,
        hideToolbar: false,
        minHeight: 400,
      })
    } catch (error) {
      console.error("PhoenixBlog: Failed to initialize Editor.js:", error)
    }
  },

  destroyed() {
    if (this._mql && this._onThemeChange) {
      this._mql.removeEventListener("change", this._onThemeChange)
    }
    if (this.editor && typeof this.editor.destroy === "function") {
      this.editor.destroy()
      this.editor = null
    }
  }
}

const PhoenixBlogUrlUpdate = {
  mounted() {
    this.handleEvent("update-url", ({url}) => {
      window.history.pushState({}, "", url)
    })
  }
}

const PhoenixBlogCopyLink = {
  mounted() {
    this.el.addEventListener("click", () => {
      const url = this.el.dataset.url
      navigator.clipboard.writeText(url).then(() => {
        const original = this.el.innerHTML
        this.el.innerHTML = '<svg class="size-4 text-green-500" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" /></svg>'
        setTimeout(() => { this.el.innerHTML = original }, 2000)
      })
    })
  }
}

const PhoenixBlogRegenerateSlug = {
  mounted() {
    this.el.addEventListener("click", () => {
      const titleInput = this.el.closest("form")?.querySelector('[name$="[title]"]')
      const title = titleInput ? titleInput.value : ""
      this.pushEvent("regenerate_slug", { title })
    })
  }
}

const PhoenixBlogHooks = {
  PhoenixBlogEditor,
  PhoenixBlogUrlUpdate,
  PhoenixBlogCopyLink,
  PhoenixBlogRegenerateSlug,
}

// ES module export
export { PhoenixBlogHooks, PhoenixBlogEditor, PhoenixBlogUrlUpdate, PhoenixBlogCopyLink, PhoenixBlogRegenerateSlug }

// Global export for script tag usage
if (typeof window !== "undefined") {
  window.PhoenixBlogHooks = PhoenixBlogHooks
}
