require_relative "../test_helper"

class RedisStoreTest < Minitest::Unit::TestCase
  def setup
  	@scope = ["walrus", "1234"]
    @progress = Progressrus.new(
      scope: @scope,
      id: "oemg",
      total: 100,
      name: "oemg-name"
    )

  	@another_progress = Progressrus.new(
      scope: @scope,
      id: "oemg-two",
      total: 100,
      name: "oemg-name-two"
    )

    @store = Progressrus::Store::Redis.new(::Redis.new(host: "10.0.0.10"))
  end

  def teardown
  	@store.flush(@scope)
  end

  def test_persist_should_set_key_value_if_outdated
  	@store.persist(@progress)

  	assert_equal 'oemg', @store.find(['walrus', '1234'], 'oemg').id
  end

  def test_persist_should_not_set_key_value_if_not_outdated
  	@store.redis.expects(:hset).once

  	@store.persist(@progress)
  	@store.persist(@progress)
  end

  def test_scope_should_return_progressruses_indexed_by_id
  	@store.persist(@progress)
  	@store.persist(@another_progress)
  	actual = @store.scope(@scope)
  	
  	assert_equal @progress.id, actual['oemg'].id
  	assert_equal @another_progress.id, actual['oemg-two'].id
  end

  def test_scope_should_return_an_empty_hash_if_nothing_is_found
  	assert_equal({}, @store.scope(@scope))
  end

  def test_find_should_return_a_single_progressrus_for_scope_and_id
  	@store.persist(@progress)

  	assert_equal @progress.id, @store.find(@scope, 'oemg').id
  end

  def test_find_should_return_nil_if_nothing_is_found
  	assert_equal nil, @store.find(@scope, 'oemg')
  end

  def test_flush_should_delete_by_scope
  	@store.persist(@progress)
  	@store.persist(@another_progress)

  	@store.flush(@scope)

  	assert_equal({}, @store.scope(@scope))
  end

  def test_flush_should_delete_by_scope_and_id
	  @store.persist(@progress)
  	@store.persist(@another_progress)

	  @store.flush(@scope, 'oemg')
  	
  	assert_equal nil, @store.find(@scope, 'oemg')
  	assert @store.find(@scope, 'oemg-two')
  end

  def test_initializes_name_to_redis
  	assert_equal :redis, @store.name 
  end

  def test_persist_should_not_write_by_default
    @store.redis.expects(:hset).once

    @store.persist(@progress)
    @store.persist(@progress)
  end

  def test_persist_should_write_if_forced
    @store.redis.expects(:hset).twice
    
    @store.persist(@progress)
    @store.persist(@progress, force: true)
  end

end
