defmodule Myapp.MarkdownRenderer do
  @moduledoc """
  Module for rendering markdown files to HTML.
  """

  @doc """
  Reads a markdown file from the given path and returns the HTML content.
  If the file does not exist, returns an error tuple.
  """
  def render_markdown_file(path) do
    case File.read(path) do
      {:ok, content} -> 
        {:ok, render_markdown(content)}
      {:error, reason} -> 
        {:error, "Could not read markdown file: #{reason}"}
    end
  end

  @doc """
  Converts markdown text to HTML.
  """
  def render_markdown(markdown) do
    Earmark.as_html!(markdown, %Earmark.Options{
      code_class_prefix: "language-",
      smartypants: false
    })
  end

  @doc """
  Gets a list of available markdown files in the docs directory.
  Returns a list of document names without the .md extension.
  """
  def get_available_docs do
    docs_path = Path.join(:code.priv_dir(:myapp), "../docs")
    
    case File.ls(docs_path) do
      {:ok, files} ->
        files
        |> Enum.filter(&String.ends_with?(&1, ".md"))
        |> Enum.map(&String.replace(&1, ".md", ""))
        |> Enum.sort()
      {:error, _} ->
        []
    end
  end

  @doc """
  Gets the path to a markdown file in the docs directory.
  """
  def get_doc_path(doc_name) do
    Path.join(:code.priv_dir(:myapp), "../docs/#{doc_name}.md")
  end
end