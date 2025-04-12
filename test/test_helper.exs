ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Myapp.Repo, :manual)

# Define mocks for testing
Mox.defmock(Myapp.MockThreads, for: Myapp.Threads.Behaviour)
Mox.defmock(Myapp.MockTokens, for: Myapp.TokensBehaviour)
