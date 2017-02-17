# TODO(mtwilliams): Test string backed enums more thoroughly.

defmodule EctoEnumTest do
  use ExUnit.Case

  import Ecto.Changeset

  import EctoEnum, only: [defenum: 2]

  defenum StatusEnum, registered: 0, active: 1, inactive: 2, archived: 3
  # defenum RoleEnum, ~w(user moderator administrator)a
  defenum RoleEnum, [:user, :moderator, :administrator]

  defmodule User do
    use Ecto.Schema

    schema "users" do
      field :status, StatusEnum
      field :role, RoleEnum
    end
  end

  alias Ecto.Integration.TestRepo

  test "accepts string or atom on save" do
    user = TestRepo.insert!(%User{})

    user = Ecto.Changeset.change(user, status: :active)
    user = TestRepo.update! user
    assert user.status == :active

    user = Ecto.Changeset.change(user, status: "inactive")
    user = TestRepo.update! user
    assert user.status == "inactive"

    user = TestRepo.get(User, user.id)
    assert user.status == :inactive

    TestRepo.insert!(%User{status: :archived})
    user = TestRepo.get_by(User, status: :archived)
    assert user.status == :archived

    user = Ecto.Changeset.change(user, role: :user)
    user = TestRepo.update! user
    assert user.role == :user

    user = Ecto.Changeset.change(user, role: "moderator")
    user = TestRepo.update! user
    assert user.role == "moderator"

    user = TestRepo.get(User, user.id)
    assert user.role == :moderator

    TestRepo.insert!(%User{role: :administrator})
    user = TestRepo.get_by(User, role: :administrator)
    assert user.role == :administrator
  end

  test "casts binary to atom" do
    %{changes: changes} = cast(%User{}, %{"status" => "active"}, ~w(status), [])
    assert changes.status == :active

    %{changes: changes} = cast(%User{}, %{"status" => :inactive}, ~w(status), [])
    assert changes.status == :inactive
  end

  test "fails when input is an integer" do
    error = {:status, {"is invalid", [type: EctoEnumTest.StatusEnum]}}

    changeset = cast(%User{}, %{"status" => 4}, ~w(status), [])
    assert error in changeset.errors

    assert_raise Ecto.ChangeError, fn ->
      TestRepo.insert!(%User{status: 5})
    end
  end

  test "fails when input is not a member" do
    error = {:status, {"is invalid", [type: EctoEnumTest.StatusEnum]}}

    changeset = cast(%User{}, %{"status" => "retroactive"}, ~w(status), [])
    assert error in changeset.errors

    changeset = cast(%User{}, %{"status" => :retroactive}, ~w(status), [])
    assert error in changeset.errors

    assert_raise Ecto.ChangeError, fn ->
      TestRepo.insert!(%User{status: "retroactive"})
    end

    assert_raise Ecto.ChangeError, fn ->
      TestRepo.insert!(%User{status: :retroactive})
    end
  end

  test "reflection" do
    assert StatusEnum.__members__() == [:active, :archived, :inactive, :registered]
    assert StatusEnum.__mappings__() == %{registered: 0, active: 1, archived: 3, inactive: 2}

    assert RoleEnum.__members__() == [:administrator, :moderator, :user]
    assert RoleEnum.__mappings__() == %{user: "user", moderator: "moderator", administrator: "administrator"}
  end

  test "defenum/2 accepts variables" do
    meaning_of_life = 42
    defenum TestEnum, question: meaning_of_life
  end

  test "defenum/2 raises conflicting type errors" do
    assert_raise EctoEnum.ConflictingTypesError, fn ->
      defenum TestEnum, active: 1, inactive: 2, archived: "archived"
    end

    assert_raise EctoEnum.ConflictingTypesError, fn ->
      defenum TestEnum, active: "active", inactive: "inactive", archived: 3
    end

    assert_raise EctoEnum.ConflictingTypesError, fn ->
      defenum TestEnum, active: 1, inactive: "inactive"
    end
  end
end
