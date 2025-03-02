defmodule MyappWeb.Components.Docs.StaticContent do
  use MyappWeb, :html

  attr :content, :string, required: true
  attr :topic, :string, required: true

  def static_content(assigns) do
    content_with_ids = add_ids_to_headings(assigns.content)
    assigns = assign(assigns, :processed_content, content_with_ids)
    
    ~H"""
    <div class="static-content prose prose-blue max-w-none">
      <%= raw(@processed_content) %>
      <style>
        /* Add responsive styles for content */
        .static-content {
          font-size: 0.875rem;
          line-height: 1.5;
          overflow-wrap: break-word;
          word-wrap: break-word;
          word-break: normal;
          hyphens: auto;
        }
        
        @media (min-width: 640px) {
          .static-content {
            font-size: 1rem;
            line-height: 1.625;
          }
        }
        
        /* Code block overflow handling */
        .static-content pre {
          overflow-x: auto;
          white-space: pre;
          max-width: 100%;
          border-radius: 0.375rem;
          background-color: #f8f9fa;
          padding: 1rem;
          position: relative;
          margin: 1rem 0;
          border: 1px solid #e5e7eb;
        }
        
        /* Add scroll indicator for code blocks that overflow */
        .static-content pre::-webkit-scrollbar {
          height: 6px;
        }
        
        .static-content pre::-webkit-scrollbar-thumb {
          background-color: rgba(156, 163, 175, 0.5);
          border-radius: 3px;
        }
        
        /* Add scroll indicator for code blocks that overflow */
        .static-content pre.has-overflow::after {
          content: "";
          position: absolute;
          bottom: 0;
          right: 0;
          height: 100%;
          width: 20px;
          background: linear-gradient(to right, rgba(248, 249, 250, 0), rgba(248, 249, 250, 1));
          pointer-events: none;
        }
        
        /* Table overflow handling */
        .static-content table {
          display: block;
          width: 100%;
          overflow-x: auto;
          border-collapse: collapse;
          margin: 1rem 0;
          font-size: 0.875rem;
        }
        
        .static-content th,
        .static-content td {
          padding: 0.5rem;
          border: 1px solid #e5e7eb;
          min-width: 120px;
        }
        
        .static-content th {
          background-color: #f8f9fa;
          font-weight: 600;
        }
        
        /* Improved image handling */
        .static-content img {
          max-width: 100%;
          height: auto;
          border-radius: 0.375rem;
          margin: 1rem 0;
        }
        
        /* Ensure inline code doesn't cause horizontal overflow */
        .static-content code:not(pre code) {
          word-break: break-word;
          white-space: pre-wrap;
          background-color: #f1f5f9;
          padding: 0.125rem 0.25rem;
          border-radius: 0.25rem;
          font-size: 0.875em;
        }
        
        /* Responsive blockquote */
        .static-content blockquote {
          border-left: 4px solid #e5e7eb;
          padding-left: 1rem;
          margin-left: 0;
          color: #4b5563;
          font-style: italic;
        }
        
        /* Ensure links don't overflow */
        .static-content a {
          word-break: break-word;
          overflow-wrap: break-word;
        }
        
        /* Responsive list items */
        .static-content ul, 
        .static-content ol {
          padding-left: 1.5rem;
        }
        
        .static-content li {
          margin-bottom: 0.5rem;
        }
        
        /* Add proper spacing for headings */
        .static-content h1, 
        .static-content h2, 
        .static-content h3, 
        .static-content h4, 
        .static-content h5, 
        .static-content h6 {
          margin-top: 1.5rem;
          margin-bottom: 1rem;
          font-weight: 600;
          line-height: 1.25;
          scroll-margin-top: 80px; /* Ensures the heading isn't hidden under any fixed headers when scrolled to */
        }
        
        .static-content h3 {
          font-size: 1.25rem;
          padding-top: 0.5rem;
        }
        
        @media (min-width: 640px) {
          .static-content h3 {
            font-size: 1.5rem;
          }
        }
      </style>
    </div>
    """
  end
  
  @doc """
  Adds IDs to h3 headings in the HTML content if they don't already have IDs.
  Uses the same ID generation logic as the TableOfContents component.
  """
  def add_ids_to_headings(html_content) when is_binary(html_content) do
    # Find h3 tags without IDs
    heading_without_id_regex = ~r/<h3(?![^>]*id=)([^>]*)>([^<]+)<\/h3>/
    
    # Replace them with h3 tags that have IDs
    Regex.replace(heading_without_id_regex, html_content, fn _, attrs, heading ->
      id = generate_id_from_heading(heading)
      "<h3#{attrs} id=\"#{id}\">#{heading}</h3>"
    end)
  end
  
  def add_ids_to_headings(nil), do: ""
  
  @doc """
  Generates a URL-friendly ID from a heading text.
  Converts to lowercase, replaces spaces with hyphens, removes special characters.
  This is the same logic used in the TableOfContents component to ensure consistency.
  """
  def generate_id_from_heading(heading) do
    heading
    |> String.downcase()
    |> String.replace(~r/[^\w\s-]/, "")  # Remove special chars except whitespace and hyphens
    |> String.replace(~r/\s+/, "-")      # Replace whitespace with hyphens
    |> String.trim("-")                  # Trim leading/trailing hyphens
  end
end
