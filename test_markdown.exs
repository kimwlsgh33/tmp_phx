# First, test available docs
IO.puts("Testing the MarkdownRenderer:")
docs = Myapp.MarkdownRenderer.get_available_docs()
IO.puts("Available docs: #{inspect(docs)}")

# Then, test rendering LLC.md
llc_path = Myapp.MarkdownRenderer.get_doc_path("LLC")
IO.puts("LLC document path: #{llc_path}")

case Myapp.MarkdownRenderer.render_markdown_file(llc_path) do
  {:ok, html_content} ->
    IO.puts("Successfully rendered LLC.md to HTML")
    IO.puts("First 100 characters: #{String.slice(html_content, 0..100)}")
  {:error, reason} ->
    IO.puts("Error rendering LLC.md: #{reason}")
end