defmodule PhoenixBlog.Web.CoreComponents do
  @moduledoc false

  use Phoenix.Component
  alias Phoenix.LiveView.JS

  # ============================================
  # Flash
  # ============================================

  attr :flash, :map, required: true

  def flash_group(assigns) do
    ~H"""
    <div class="fixed top-4 right-4 z-50 space-y-2">
      <.flash :for={{kind, msg} <- @flash} kind={kind} message={msg} />
    </div>
    """
  end

  attr :kind, :string, required: true
  attr :message, :string, required: true

  defp flash(assigns) do
    ~H"""
    <div
      role="alert"
      class={[
        "flex items-center gap-3 px-4 py-3 rounded-lg shadow-lg text-sm max-w-sm animate-slide-in",
        flash_class(@kind)
      ]}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> JS.hide()}
    >
      <span class="flex-1">{@message}</span>
      <button type="button" class="opacity-60 hover:opacity-100">&times;</button>
    </div>
    """
  end

  defp flash_class("info"), do: "bg-blue-50 dark:bg-blue-950 text-blue-800 dark:text-blue-200 border border-blue-200 dark:border-blue-800"
  defp flash_class("error"), do: "bg-red-50 dark:bg-red-950 text-red-800 dark:text-red-200 border border-red-200 dark:border-red-800"
  defp flash_class(_), do: "bg-gray-50 dark:bg-gray-900 text-gray-800 dark:text-gray-200 border border-gray-200 dark:border-gray-700"

  # ============================================
  # Icon (Heroicons via CSS class)
  # ============================================

  attr :name, :string, required: true
  attr :class, :string, default: "size-5"

  def icon(assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  # ============================================
  # Input
  # ============================================

  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any
  attr :type, :string, default: "text"
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :errors, :list, default: []
  attr :options, :list, default: nil
  attr :rest, :global, include: ~w(
    accept autocomplete capture cols disabled form list max maxlength min minlength
    multiple pattern placeholder readonly required rows size step phx-debounce
  )
  attr :class, :string, default: nil

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn ->
      if assigns.type == "checkbox", do: field.name <> "[]", else: field.name
    end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div>
      <label :if={@label} for={@id} class="block text-sm font-medium text-gray-900 dark:text-gray-100 mb-1">
        {@label}
      </label>
      <select
        id={@id}
        name={@name}
        class={@class || "w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 px-3 py-2 text-sm shadow-sm focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"}
        {@rest}
      >
        {Phoenix.HTML.Form.options_for_select(@options || [], @value)}
      </select>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div>
      <label :if={@label} for={@id} class="block text-sm font-medium text-gray-900 dark:text-gray-100 mb-1">
        {@label}
      </label>
      <textarea
        id={@id}
        name={@name}
        class={@class || "w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 px-3 py-2 text-sm shadow-sm focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"}
        {@rest}
      >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(assigns) do
    ~H"""
    <div>
      <label :if={@label} for={@id} class="block text-sm font-medium text-gray-900 dark:text-gray-100 mb-1">
        {@label}
      </label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={@class || "w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 px-3 py-2 text-sm shadow-sm focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"}
        {@rest}
      />
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  slot :inner_block, required: true

  defp error(assigns) do
    ~H"""
    <p class="mt-1 text-xs text-red-600 dark:text-red-400">
      {render_slot(@inner_block)}
    </p>
    """
  end

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", fn _ -> to_string(value) end)
    end)
  end
end
