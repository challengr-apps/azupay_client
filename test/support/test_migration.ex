defmodule Azupay.TestMigration do
  use Ecto.Migration

  def up, do: Azupay.MockServer.Migrations.up(version: 1)
  def down, do: Azupay.MockServer.Migrations.down(version: 1)
end
