class BananaPolicy < ApplicationPolicy
  def show?
    update?
  end

  def edit?
    update?
  end

  def update?
    user_owns_record?
  end

  def destroy?
    update?
  end
end
