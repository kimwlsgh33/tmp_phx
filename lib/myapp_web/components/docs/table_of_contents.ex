defmodule MyappWeb.Components.Docs.TableOfContents do
  use MyappWeb, :html
  
  def table_of_contents(assigns) do
    ~H"""
    <div class="mb-8 p-4 bg-blue-50 rounded-lg">
      <h3 class="text-sm font-semibold text-blue-800 uppercase tracking-wide mb-2">
        Table of Contents
      </h3>
      <ul class="space-y-1 text-sm">
        <li>
          <a href="#key-points" class="text-blue-700 hover:underline">Key Points</a>
        </li>
        <li>
          <a href="#what-is-an-llc" class="text-blue-700 hover:underline">
            What is an LLC?
          </a>
        </li>
        <li>
          <a href="#how-to-form-an-llc" class="text-blue-700 hover:underline">
            How to Form an LLC
          </a>
        </li>
        <li>
          <a href="#why-delaware-stands-out" class="text-blue-700 hover:underline">
            Why Delaware Stands Out
          </a>
        </li>
        <li>
          <a href="#practical-considerations" class="text-blue-700 hover:underline">
            Practical Considerations
          </a>
        </li>
        <li>
          <a href="#example" class="text-blue-700 hover:underline">
            Example: Single-Member LLC Tax Filing
          </a>
        </li>
        <li>
          <a href="#comprehensive-analysis" class="text-blue-700 hover:underline">
            Comprehensive Analysis
          </a>
        </li>
      </ul>
    </div>
    """
  end
end
