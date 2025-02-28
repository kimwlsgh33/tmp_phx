defmodule MyappWeb.DocsComponents do
  @moduledoc """
  Documentation components for the application.
  """

  alias MyappWeb.Components.Docs.{
    Breadcrumb,
    Sidebar,
    TableOfContents,
    ContentHeader,
    FeedbackSection,
    RelatedDocs,
    StaticContent
  }

  # Re-export all components
  defdelegate breadcrumb(assigns), to: Breadcrumb
  defdelegate sidebar(assigns), to: Sidebar
  defdelegate table_of_contents(assigns), to: TableOfContents
  defdelegate content_header(assigns), to: ContentHeader
  defdelegate feedback_section(assigns), to: FeedbackSection
  defdelegate related_docs(assigns), to: RelatedDocs
  defdelegate static_content(assigns), to: StaticContent
end
