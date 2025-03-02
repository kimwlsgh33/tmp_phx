defmodule MyappWeb.Components.Docs.TableOfContents do
  use MyappWeb, :html
  alias MyappWeb.Components.Docs.StaticContent

  attr :content, :string, required: true

  def table_of_contents(assigns) do
    ~H"""
    <div class="mb-4 sm:mb-8 p-3 sm:p-4 bg-blue-50 rounded-lg">
      <h3 class="text-xs sm:text-sm font-semibold text-blue-800 uppercase tracking-wide mb-2">
        TABLE OF CONTENTS
      </h3>
      <div class="overflow-x-auto">
        <ul class="space-y-1 text-xs sm:text-sm">
          <%= for {heading, id} <- extract_headings(@content) do %>
            <li>
              <a 
                href={"##{id}"} 
                class="toc-link text-blue-700 hover:underline block overflow-hidden text-ellipsis whitespace-nowrap"
                phx-click={JS.push("scroll_to_section", value: %{id: id})}
              >
                <%= heading %>
              </a>
            </li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end

  @doc """
  Extracts headings from markdown HTML content.
  Returns a list of {heading_text, heading_id} tuples.
  If headings don't have IDs, generates them from the heading text.
  """
  def extract_headings(html_content) when is_binary(html_content) do
    # First, try to find h3 tags with IDs already assigned
    heading_with_id_regex = ~r/<h3.*?id="([^"]+)".*?>([^<]+)<\/h3>/
    headings_with_ids = Regex.scan(heading_with_id_regex, html_content)
                       |> Enum.map(fn [_, id, heading] -> {heading, id} end)
    
    # Also find h3 tags without IDs
    heading_without_id_regex = ~r/<h3(?![^>]*id=)[^>]*>([^<]+)<\/h3>/
    headings_without_ids = Regex.scan(heading_without_id_regex, html_content)
                          |> Enum.map(fn [_, heading] -> 
                               id = StaticContent.generate_id_from_heading(heading)
                               {heading, id}
                             end)
    
    # Combine both results
    headings_with_ids ++ headings_without_ids
  end

  def extract_headings(_), do: []
end
