defmodule MyappWeb.Components.Docs.ContentHeader do
  use MyappWeb, :html

  attr :topic, :string, required: true

  def content_header(assigns) do
    ~H"""
    <div class="px-4 sm:px-6 py-4 sm:py-5 border-b border-gray-200 bg-gray-50">
      <div class="flex items-center justify-between">
        <div class="flex-1 min-w-0">
          <h1 class="text-xl sm:text-2xl font-bold text-gray-900 truncate">{String.capitalize(@topic)}</h1>
          <p class="mt-1 text-xs sm:text-sm text-gray-500">Last updated: February 25, 2025</p>
        </div>
        <!-- Mobile menu button (only visible on mobile) -->
        <button
          type="button"
          class="md:hidden p-2 rounded-md text-gray-500 hover:text-gray-600 hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
          aria-controls="mobile-menu"
          aria-expanded="false"
          id="mobile-menu-button"
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
    </div>
    """
  end
end
