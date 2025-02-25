defmodule MyappWeb.Components.Docs.ContentHeader do
  use MyappWeb, :html
  
  attr :topic, :string, required: true

  def content_header(assigns) do
    ~H"""
    <div class="px-6 py-5 border-b border-gray-200 bg-gray-50">
      <div class="flex items-center justify-between">
        <h1 class="text-2xl font-bold text-gray-900">{String.capitalize(@topic)}</h1>
        <!-- Mobile menu button (only visible on mobile) -->
        <button
          type="button"
          class="md:hidden p-2 rounded-md text-gray-500 hover:text-gray-600 hover:bg-gray-100"
        >
          <span class="sr-only">Open navigation menu</span>
          <svg
            class="h-6 w-6"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M4 6h16M4 12h16M4 18h16"
            />
          </svg>
        </button>
      </div>
      <p class="mt-1 text-sm text-gray-500">Last updated: February 25, 2025</p>
    </div>
    """
  end
end
