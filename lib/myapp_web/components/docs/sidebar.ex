defmodule MyappWeb.Components.Docs.Sidebar do
  use MyappWeb, :html

  attr :topic, :string, required: true

  def sidebar(assigns) do
    ~H"""
    <div class="w-full">
      <div class="lg:sticky lg:top-8">
        <h4 class="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-3">
          Documentation
        </h4>
        <nav class="space-y-1">
          <%= for doc <- ["Cloudflare", "LLC", "Tiktok", "Youtube", "getting-started", "features", "api"] do %>
            <a
              href={~p"/docs/#{doc}"}
              class={"group flex items-center px-3 py-2 text-sm font-medium rounded-md " <> 
                if @topic == doc, 
                do: "bg-blue-50 text-blue-700", 
                else: "text-gray-700 hover:text-blue-700 hover:bg-blue-50"
              }
            >
              <span class="truncate">{String.capitalize(doc)}</span>
            </a>
          <% end %>
        </nav>
      </div>
    </div>
    """
  end
end
