require 'test_helper'

class ActivePodioTest < Test::Unit::TestCase

  class TestAssociationModel < ActivePodio::Base
    property :string, :string
  end

  class TestModel < ActivePodio::Base
    property :test_id, :integer
    property :string, :string
    property :hash_property, :hash
    property :prefixed_hash_property, :hash
    property :hash_property_with_setter, :hash
    property :prefixed_hash_property_with_setter, :hash
    property :datetime, :datetime
    property :date, :date
    property :integer, :integer
    property :boolean, :boolean
    property :array, :array
    
    has_one :association, :class => 'ActivePodioTest::TestAssociationModel'
    has_one :different_association, :class => 'ActivePodioTest::TestAssociationModel', :property => :other_association
    has_many :associations, :class => 'ActivePodioTest::TestAssociationModel'
    has_many :different_associations, :class => 'ActivePodioTest::TestAssociationModel', :property => :other_associations
    
    alias_method :id, :test_id
    
    delegate_to_hash :hash_property, :key1, :key2, :really?
    delegate_to_hash :prefixed_hash_property, :key3, :prefix => true
    delegate_to_hash :hash_property_with_setter, :key4, :setter => true
    delegate_to_hash :prefixed_hash_property_with_setter, :key5, :setter => true, :prefix => true
    
    
    def save(exception_class = nil)
      if exception_class
        raise exception_class.new({
          'error' => 'test status',
          'error_description' => 'test desc',
          'error_parameters' => 'test parms'
          }, 500, 'http://api.podio.dev')
      end
    end
    
    handle_api_errors_for :save
  end
  
  test 'should instansiate model' do
    @test = TestModel.new
    assert_not_nil @test
  end
  
  test 'should support string property' do
    @test = TestModel.new(:string => 'string')
    assert_equal 'string', @test.string
  end

  test 'should support hash property' do
    @test = TestModel.new(:hash_property => { :key => 'value' })
    assert_equal({ :key => 'value' }, @test.hash_property)
  end
  
  test 'should store given datetime as a db string internally' do
    @test = TestModel.new(:datetime => DateTime.new(2011, 6, 7, 22, 5, 0))
    assert_equal '2011-06-07 22:05:00', @test[:datetime]
  end

  test 'should expose datetime string as datetime' do
    @test = TestModel.new(:datetime => '2011-06-07 22:05:00')
    assert_equal DateTime.new(2011, 6, 7, 22, 5, 0), @test.datetime
  end

  test 'should store given date as a db string internally' do
    @test = TestModel.new(:date => Date.new(2011, 6, 7))
    assert_equal '2011-06-07', @test[:date]
  end

  test 'should expose date string as date' do
    @test = TestModel.new(:date => '2011-06-07')
    assert_equal Date.new(2011, 6, 7), @test.date
  end
  
  test 'should store given integer string as integer internally' do
    @test = TestModel.new(:integer => "42")
    assert_equal 42, @test[:integer]
  end

  test 'should expose blank integer string as nil' do
    @test = TestModel.new(:integer => "")
    assert_nil @test.integer
  end
  
  [true, 'true', 1, '1', 'yes'].each do |boolean_value|
    test "should store and expose given boolean value #{boolean_value} (#{boolean_value.class.name}) as true" do
      @test = TestModel.new(:boolean => boolean_value)
      assert @test.boolean
    end
  end

  [false, 'false', 0, '0', 'no', 'whatever'].each do |boolean_value|
    test "should store and expose given boolean value #{boolean_value} (#{boolean_value.class.name}) as false" do
      @test = TestModel.new(:boolean => boolean_value)
      assert_equal false, @test.boolean
    end
  end
  
  test "should expose singular array getter" do
    @test = TestModel.new(:array => ['foo', 'bar'])
    assert_equal ['foo', 'bar'], @test.array
  end

  test "should expose singular array setter" do
    @test = TestModel.new
    @test.array = ['foo', 'bar']
    assert_equal ['foo', 'bar'], @test.array
  end

  test "should expose plural array getter" do
    @test = TestModel.new(:array => ['foo', 'bar'])
    assert_equal ['foo', 'bar'], @test.arrays
  end

  test "should expose plural array setter" do
    @test = TestModel.new
    @test.arrays = ['foo', 'bar']
    assert_equal ['foo', 'bar'], @test.arrays
  end

  test "should expose default array getter" do
    @test = TestModel.new(:array => ['foo', 'bar'])
    assert_equal 'foo', @test.default_array
  end
  
  test 'should expose has one association' do
    @test = TestModel.new(:association => { :string => 'association string' })
    assert_equal 'association string', @test.association.string
  end

  test 'should expose nil has one association when no data given' do
    @test = TestModel.new
    assert_nil @test.association
  end

  test 'should use property option when given to has one association' do
    @test = TestModel.new(:other_association => { :string => 'other association' })
    assert_equal 'other association', @test.different_association.string
  end

  test 'should expose has many association' do
    @test = TestModel.new(:associations => [{ :string => 'association string 1' }, { :string => 'association string 2' }])
    assert_equal 'association string 1', @test.associations[0].string
    assert_equal 'association string 2', @test.associations[1].string
  end

  test 'should expose empty has many association when no data given' do
    @test = TestModel.new
    assert_equal [], @test.associations
  end

  test 'should use property option when given to has many association' do
    @test = TestModel.new(:other_associations => [{ :string => 'other association 1' }, { :string => 'other association 2' }])
    assert_equal 'other association 1', @test.different_associations[0].string
    assert_equal 'other association 2', @test.different_associations[1].string
  end
  
  test 'should expose getter methods defined by delegate to hash' do
    @test = TestModel.new(:hash_property => {'key1' => 'value1', 'key2' => 'value2', 'really' => true})
    assert_equal 'value1', @test.key1
    assert @test.really?
  end

  test 'should expose prefixed getter methods defined by delegate to hash' do
    @test = TestModel.new(:prefixed_hash_property => {'key3' => 'value3'})
    assert_equal 'value3', @test.prefixed_hash_property_key3
  end

  test 'should expose setter methods defined by delegate to hash' do
    @test = TestModel.new(:hash_property_with_setter => {'key4' => 'value4'})
    assert_equal 'value4', @test.key4
    @test.key4 = 'new'
    assert_equal 'new', @test.key4
  end

  test 'should expose prefixed getter and setter methods defined by delegate to hash' do
    @test = TestModel.new(:prefixed_hash_property_with_setter => {'key5' => 'value5'})
    assert_equal 'value5', @test.prefixed_hash_property_with_setter_key5
    @test.prefixed_hash_property_with_setter_key5 = 'new'
    assert_equal 'new', @test.prefixed_hash_property_with_setter_key5
  end

  test 'should work with delegate to hash getter when hash is nil' do
    @test = TestModel.new
    assert_nil @test.key4
  end

  test 'should work with delegate to hashsetter when hash is nil' do
    @test = TestModel.new
    @test.key4 = 'new'
    assert_equal 'new', @test.key4
  end
  
  test 'should handle non failing api requests' do
    @test = TestModel.new
    assert @test.save
  end

  [Podio::BadRequestError, Podio::AuthorizationError].each do |exception_class|
    test "should handle failing api requests with #{exception_class.name} exception" do
      @test = TestModel.new
      assert_equal false, @test.save(exception_class)
      assert_equal 'test status', @test.error_code
      assert_equal 'test desc', @test.error_message
      assert_equal 'test parms', @test.error_parameters
    end
  end
  
  test 'should return instance from member' do
    assert TestModel.member(:string => 'string').instance_of?(TestModel)
  end

  test 'should return array of instances from list' do
    instances = TestModel.list([{:string => 'first'}, {:string => 'last'}])
    assert_equal 2, instances.length
    assert instances.all? { |instance| instance.instance_of?(TestModel) }
    assert_equal 'first', instances.first.string
    assert_equal 'last', instances.last.string
  end
  
  test 'should return struct with count, total and array from collection' do
    struct = TestModel.collection('items' => [{:string => 'first'}, {:string => 'last'}], 'filtered' => 10, 'total' => 50)
    assert_equal 2, struct.all.length
    assert struct.all.all? { |instance| instance.instance_of?(TestModel) }
    assert_equal 10, struct.count
    assert_equal 50, struct.total_count
  end
  
  test 'should be new record without id' do
    @test = TestModel.new
    assert @test.new_record?
  end

  test 'should not be new record with id' do
    @test = TestModel.new(:test_id => 42)
    assert_equal false, @test.new_record?
  end

  test 'should not be persisted without id' do
    @test = TestModel.new
    assert_equal false, @test.persisted?
  end

  test 'should be persisted with id' do
    @test = TestModel.new(:test_id => 42)
    assert @test.persisted?
  end
  
  test 'should return id as to_param' do
    @test = TestModel.new(:test_id => 42)
    assert_equal '42', @test.to_param
  end

  test 'should return nil as to_param when model has no id' do
    @test = TestAssociationModel.new
    assert_nil @test.to_param
  end
  
  test 'should initialize nil attributes when constructed without given attributes' do
    @test = TestModel.new
    assert_equal({:string=>nil, :test_id=>nil, :hash_property=>nil, :prefixed_hash_property=>nil, :hash_property_with_setter=>nil, :prefixed_hash_property_with_setter=>nil, :datetime=>nil, :date=>nil, :integer=>nil, :boolean=>nil, :array=>nil}, @test.attributes)
  end

  test 'should accept unknown properties when constructed' do
    @test = TestModel.new(:unknown => 'attribute')
    assert_equal({:string=>nil, :test_id=>nil, :hash_property=>nil, :prefixed_hash_property=>nil, :hash_property_with_setter=>nil, :prefixed_hash_property_with_setter=>nil, :datetime=>nil, :date=>nil, :integer=>nil, :boolean=>nil, :array=>nil, :unknown => 'attribute'}, @test.attributes)
  end
  
  test 'should use id for ==' do
    @test1 = TestModel.new(:test_id => 42)
    @test2 = TestModel.new(:test_id => 42)
    assert @test1 == @test2
  end
  
  test 'should use hashed id for hash' do
    @test = TestModel.new(:test_id => 42)
    assert_equal 42.hash, @test.hash
  end

  test 'should return attributes for as_json' do
    @test = TestModel.new(:test_id => 42)
    assert_equal({:id=> 42, :string=>nil, :test_id=>42, :hash_property=>nil, :prefixed_hash_property=>nil, :hash_property_with_setter=>nil, :prefixed_hash_property_with_setter=>nil, :datetime=>nil, :date=>nil, :integer=>nil, :boolean=>nil, :array=>nil}, @test.as_json)
  end
  
end