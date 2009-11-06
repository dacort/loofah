require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class TestFilter < Test::Unit::TestCase

  FRAGMENT = "<span>hello</span><span>goodbye</span>"
  FRAGMENT_NODE_COUNT         = 4 # span, text, span, text
  FRAGMENT_NODE_STOP_TOP_DOWN = 2 # span, span
  DOCUMENT = "<html><head><link></link></head><body><span>hello</span><span>goodbye</span></body></html>"
  DOCUMENT_NODE_COUNT         = 5 # span, text, span, text
  DOCUMENT_NODE_STOP_TOP_DOWN = 3 # link, span, span

  context "receiving a block" do
    setup do
      @count = 0
    end

    context "returning CONTINUE" do
      setup do
        @filter = Loofah::Filter.new do |node|
          @count += 1
          Loofah::Filter::CONTINUE
        end
      end

      should "operate properly on a fragment" do
        Loofah.scrub_fragment(FRAGMENT, @filter)
        assert_equal FRAGMENT_NODE_COUNT, @count
      end

      should "operate properly on a document" do
        Loofah.scrub_document(DOCUMENT, @filter)
        assert_equal DOCUMENT_NODE_COUNT, @count
      end
    end

    context "returning STOP" do
      setup do
        @filter = Loofah::Filter.new do |node|
          @count += 1
          Loofah::Filter::STOP
        end
      end

      should "operate as top-down on a fragment" do
        Loofah.scrub_fragment(FRAGMENT, @filter)
        assert_equal FRAGMENT_NODE_STOP_TOP_DOWN, @count
      end

      should "operate as top-down on a document" do
        Loofah.scrub_document(DOCUMENT, @filter)
        assert_equal DOCUMENT_NODE_STOP_TOP_DOWN, @count
      end
    end

    context "returning neither CONTINUE nor STOP" do
      setup do
        @filter = Loofah::Filter.new do |node|
          @count += 1
        end
      end

      should "act as if CONTINUE was returned" do
        Loofah.scrub_fragment(FRAGMENT, @filter)
        assert_equal FRAGMENT_NODE_COUNT, @count
      end
    end

    context "not specifying direction" do
      setup do
        @filter = Loofah::Filter.new() do |node|
          @count += 1
          Loofah::Filter::STOP
        end
      end

      should "operate as top-down on a fragment" do
        Loofah.scrub_fragment(FRAGMENT, @filter)
        assert_equal FRAGMENT_NODE_STOP_TOP_DOWN, @count
      end

      should "operate as top-down on a document" do
        Loofah.scrub_document(DOCUMENT, @filter)
        assert_equal DOCUMENT_NODE_STOP_TOP_DOWN, @count
      end
    end

    context "specifying top-down direction" do
      setup do
        @filter = Loofah::Filter.new(:direction => :top_down) do |node|
          @count += 1
          Loofah::Filter::STOP
        end
      end

      should "operate as top-down on a fragment" do
        Loofah.scrub_fragment(FRAGMENT, @filter)
        assert_equal FRAGMENT_NODE_STOP_TOP_DOWN, @count
      end

      should "operate as top-down on a document" do
        Loofah.scrub_document(DOCUMENT, @filter)
        assert_equal DOCUMENT_NODE_STOP_TOP_DOWN, @count
      end
    end

    context "specifying bottom-up direction" do
      setup do
        @filter = Loofah::Filter.new(:direction => :bottom_up) do |node|
          @count += 1
        end
      end

      should "operate as bottom-up on a fragment" do
        Loofah.scrub_fragment(FRAGMENT, @filter)
        assert_equal FRAGMENT_NODE_COUNT, @count
      end

      should "operate as bottom-up on a document" do
        Loofah.scrub_document(DOCUMENT, @filter)
        assert_equal DOCUMENT_NODE_COUNT, @count
      end
    end

    context "invalid direction" do
      should "raise an exception" do
        assert_raises(ArgumentError) {
          Loofah::Filter.new(:direction => :quux) { }
        }
      end
    end

    context "given a block taking zero arguments" do
      setup do
        @filter = Loofah::Filter.new do
          @count += 1
        end
      end

      should "work anyway, shrug" do
        Loofah.scrub_fragment(FRAGMENT, @filter)
        assert_equal FRAGMENT_NODE_COUNT, @count
      end
    end
  end

  context "defining a new Filter class" do
    setup do
      @klass = Class.new(Loofah::Filter) do
        attr_accessor :count
        def initialize(direction=nil)
          @direction = direction
          @count = 0
        end
        def filter(node)
          @count += 1
          Loofah::Filter::STOP
        end
      end
    end

    context "when not specifying direction" do
      setup do
        @filter = @klass.new
        assert_nil @filter.direction
      end

      should "operate as top-down on a fragment" do
        Loofah.scrub_fragment(FRAGMENT, @filter)
        assert_equal FRAGMENT_NODE_STOP_TOP_DOWN, @filter.count
      end

      should "operate as top-down on a document" do
        Loofah.scrub_document(DOCUMENT, @filter)
        assert_equal DOCUMENT_NODE_STOP_TOP_DOWN, @filter.count
      end
    end

    context "when direction is specified as top_down" do
      setup do
        @filter = @klass.new(:top_down)
        assert_equal :top_down, @filter.direction
      end

      should "operate as top-down on a fragment" do
        Loofah.scrub_fragment(FRAGMENT, @filter)
        assert_equal FRAGMENT_NODE_STOP_TOP_DOWN, @filter.count
      end

      should "operate as top-down on a document" do
        Loofah.scrub_document(DOCUMENT, @filter)
        assert_equal DOCUMENT_NODE_STOP_TOP_DOWN, @filter.count
      end
    end

    context "when direction is specified as bottom_up" do
      setup do
        @filter = @klass.new(:bottom_up)
        assert_equal :bottom_up, @filter.direction
      end

      should "operate as bottom-up on a fragment" do
        Loofah.scrub_fragment(FRAGMENT, @filter)
        assert_equal FRAGMENT_NODE_COUNT, @filter.count
      end

      should "operate as bottom-up on a document" do
        Loofah.scrub_document(DOCUMENT, @filter)
        assert_equal DOCUMENT_NODE_COUNT, @filter.count
      end
    end
  end

  context "creating a new Filter class with no filter method" do
    setup do
      @klass = Class.new(Loofah::Filter) do
        def initialize ; end
      end
      @filter = @klass.new
    end

    should "raise an exception" do
      assert_raises(Loofah::FilterNotFound) {
        Loofah.scrub_fragment(FRAGMENT, @filter)
      }
    end
  end
end
