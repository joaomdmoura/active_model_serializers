require 'minitest/autorun'
require 'rugged'

module BenchmarkHelper
  Routes = ActionDispatch::Routing::RouteSet.new
  Routes.draw do
    get ':controller(/:action(/:id))'
    get ':controller(/:action)'
  end

  ActionController::Base.send :include, Routes.url_helpers
end

ActionController::TestCase.class_eval do
  def setup
    @repo = Rugged::Repository.new('.')
    @ref  = repo.head

    @actual_commit = ref.target.oid
    @last_commit   = ref.target.parents.last.oid
  end

  def set_commit(sha)
    @repo.checkout sha
  end
end