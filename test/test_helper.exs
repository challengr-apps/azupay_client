# Ensure database exists (ignore :already_up errors)
Azupay.TestRepo.__adapter__().storage_up(Azupay.TestRepo.config())

# Start the test repo
{:ok, _} = Azupay.TestRepo.start_link(pool_size: 10)

# Run mock server migrations
Ecto.Migrator.up(Azupay.TestRepo, 1, Azupay.TestMigration)

# Set sandbox mode
Ecto.Adapters.SQL.Sandbox.mode(Azupay.TestRepo, :auto)

ExUnit.start()
