defmodule MyappWeb.Components.Docs.RelatedDocs do
  use MyappWeb, :html
  
  attr :topic, :string, required: true

  def related_docs(assigns) do
    ~H"""
    <div class="mt-8">
      <h2 class="text-lg font-medium text-gray-900">Related Documentation</h2>
      <div class="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2">
        <%= for related_doc <- (if @topic == "LLC", do: ["Cloudflare", "Youtube"], else: ["LLC", "Tiktok"]) do %>
          <div class="relative rounded-lg border border-gray-200 bg-white px-6 py-5 shadow-sm flex items-center space-x-3 hover:border-gray-400 focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-blue-500">
            <div class="flex-shrink-0">
              <span class="inline-flex items-center justify-center h-10 w-10 rounded-md bg-blue-500 text-white">
                <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
              </span>
            </div>
            <div class="flex-1 min-w-0">
              <a href={~p"/docs/#{related_doc}"} class="focus:outline-none">
                <span class="absolute inset-0" aria-hidden="true"></span>
                <p class="text-sm font-medium text-gray-900">{String.capitalize(related_doc)}</p>
                <p class="text-sm text-gray-500 truncate">
                  Learn more about {String.capitalize(related_doc)}
                </p>
              </a>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
