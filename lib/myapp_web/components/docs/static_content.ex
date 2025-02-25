defmodule MyappWeb.Components.Docs.StaticContent do
  use MyappWeb, :html
  
  attr :topic, :string, required: true

  def static_content(assigns) do
    ~H"""
    <%= case @topic do %>
      <% "getting-started" -> %>
        <h2>Getting Started Guide</h2>
        <p>
          Welcome to our platform! This guide will help you get up and running quickly.
        </p>

        <h3>Step 1: Create an Account</h3>
        <p>
          To start using our service, you'll need to create an account. Click the "Sign Up" button in the top right corner of the page and follow the instructions.
        </p>

        <h3>Step 2: Set Up Your Profile</h3>
        <p>
          Once you've created an account, you'll want to set up your profile. This helps personalize your experience and makes it easier for others to find and connect with you.
        </p>

        <h3>Step 3: Explore Features</h3>
        <p>
          Now that you're all set up, take some time to explore the features of our platform. Check out the dashboard, browse content, and familiarize yourself with the interface.
        </p>

      <% "features" -> %>
        <h2>Features Overview</h2>
        <p>
          Our platform offers a wide range of features designed to help you achieve your goals. Here's an overview of what we offer:
        </p>

        <h3>Feature 1: Collaboration Tools</h3>
        <p>
          Our collaboration tools make it easy to work with others on projects. Share documents, assign tasks, and track progress all in one place.
        </p>

        <h3>Feature 2: Analytics Dashboard</h3>
        <p>
          The analytics dashboard provides insights into your performance and helps you make data-driven decisions. Track key metrics and visualize trends over time.
        </p>

        <h3>Feature 3: Integration Options</h3>
        <p>
          Our platform integrates with a variety of third-party tools and services, allowing you to create a seamless workflow across all your applications.
        </p>

      <% "api" -> %>
        <h2>API Reference</h2>
        <p>
          Our API allows you to integrate our services into your own applications. This reference provides detailed information about endpoints, parameters, and responses.
        </p>

        <h3>Authentication</h3>
        <p>
          All API requests require authentication. You can authenticate using an API key or OAuth 2.0. See the Authentication section for more details.
        </p>

        <h3>Endpoints</h3>
        <p>
          Our API provides endpoints for managing users, content, and other resources. Each endpoint is documented with examples and response schemas.
        </p>

        <h3>Rate Limiting</h3>
        <p>
          To ensure fair usage, our API implements rate limiting. By default, you can make up to 100 requests per minute. If you need higher limits, contact our support team.
        </p>

      <% "support" -> %>
        <h2>Contact Support</h2>
        <p>
          Need help? Our support team is here to assist you. Please use one of the methods below to get in touch.
        </p>

        <h3>Email Support</h3>
        <p>
          For general inquiries, you can email us at support@example.com. We typically respond within 24 hours during business days.
        </p>

        <h3>Live Chat</h3>
        <p>
          For immediate assistance, use the live chat feature available in the bottom right corner of our website. Live chat is available Monday through Friday, 9am to 5pm EST.
        </p>

        <h3>Phone Support</h3>
        <p>
          For urgent matters, you can call our support line at +1-800-123-4567. Phone support is available Monday through Friday, 9am to 5pm EST.
        </p>

      <% _ -> %>
        <div class="text-center py-12">
          <svg
            class="mx-auto h-12 w-12 text-gray-400"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            aria-hidden="true"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
            />
          </svg>
          <h3 class="mt-2 text-sm font-medium text-gray-900">No documentation found</h3>
          <p class="mt-1 text-sm text-gray-500">
            We couldn't find any documentation for this topic.
          </p>
          <div class="mt-6">
            <a
              href={~p"/docs/getting-started"}
              class="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              <svg
                class="-ml-1 mr-2 h-5 w-5"
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 20 20"
                fill="currentColor"
                aria-hidden="true"
              >
                <path
                  fill-rule="evenodd"
                  d="M10 18a8 8 0 100-16 8 8 0 000 16zm.707-10.293a1 1 0 00-1.414-1.414l-3 3a1 1 0 000 1.414l3 3a1 1 0 001.414-1.414L9.414 11H13a1 1 0 100-2H9.414l1.293-1.293z"
                  clip-rule="evenodd"
                />
              </svg>
              Go to Getting Started
            </a>
          </div>
        </div>
    <% end %>
    """
  end
end
