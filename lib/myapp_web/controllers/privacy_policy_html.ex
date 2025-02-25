defmodule MyappWeb.PrivacyPolicyHTML do
  use MyappWeb, :html

  def page(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto py-10 px-4 sm:px-6 lg:px-8">
      <h1 class="text-3xl font-bold">Privacy Policy v{@version}</h1>
      <div class="mt-8 prose max-w-none">
        <p>
          This is a placeholder for the privacy policy content. In a real application, this would be loaded from a database or a file.
        </p>
        <p>
          The privacy policy outlines how we collect, use, and protect your personal information when you use our service.
        </p>
      </div>
    </div>
    """
  end
end
