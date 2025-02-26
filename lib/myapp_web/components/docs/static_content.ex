defmodule MyappWeb.Components.Docs.StaticContent do
  use MyappWeb, :html

  attr :content, :string, required: true
  attr :topic, :string, required: true

  def static_content(assigns) do
    ~H"""
    <div class="static-content prose prose-blue max-w-none">
      <%= raw(@content) %>
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
        
        /* Ensure URLs don't cause overflow issues */
        .static-content a {
          word-break: break-all;
          color: #2563eb;
          text-decoration: none;
        }
        
        .static-content a:hover {
          text-decoration: underline;
        }
        
        /* Improve headings */
        .static-content h3 {
          font-size: 1.25rem;
          font-weight: 600;
          margin-top: 1.5rem;
          margin-bottom: 0.75rem;
          color: #1e3a8a;
          scroll-margin-top: 70px;
        }
        
        /* Add styles for lists */
        .static-content ul, 
        .static-content ol {
          padding-left: 1.5rem;
          margin: 0.75rem 0;
        }
        
        .static-content li {
          margin-bottom: 0.5rem;
        }
        
        /* Add horizontal rule styling */
        .static-content hr {
          margin: 1.5rem 0;
          border: 0;
          border-top: 1px solid #e5e7eb;
        }
      </style>
    </div>
    """
  end
end
