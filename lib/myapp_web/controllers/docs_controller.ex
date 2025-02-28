defmodule MyappWeb.DocsController do
  use MyappWeb, :controller
  alias Myapp.MarkdownRenderer

  def index(conn, _params) do
    # Get list of available docs
    available_docs = MarkdownRenderer.get_available_docs()
    render(conn, :index, available_docs: available_docs)
  end

  def show(conn, %{"topic" => topic}) do
    # Try to find and render markdown file
    doc_path = MarkdownRenderer.get_doc_path(topic)

    case MarkdownRenderer.render_markdown_file(doc_path) do
      {:ok, html_content} ->
        render(conn, :show, topic: topic, content: html_content, from_markdown: true)

      {:error, _reason} ->
        # Fall back to static content in the template
        render(conn, :show, topic: topic, from_markdown: false)
    end
  end
end
