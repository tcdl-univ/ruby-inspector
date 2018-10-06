require_relative '../lib/ruby-inspector/static/inspector_ast'

describe 'Simple processed parse trees to inspect' do
  include AST::Sexp

  before do
    @inspector = InspectorAST.new
  end

  it 'inspect simple method' do
    source = "def simple_method
                @a = 34
              end"

    @inspector.analyze source
    expect(@inspector.processed_ast).to be_a_kind_of(DefNode)
    def_node = @inspector.processed_ast
    expect(def_node.method_name).to eq(:simple_method)
    expect(def_node.arguments).to be_a_kind_of(ArgsNode)
    expect(def_node.arguments.args.length).to eq(0)
    expect(def_node.raw_astbody).to eq(s(:ivasgn, :@a, s(:int, 34)))

  end

  it 'inspect simple method with multiple arguments' do
    source = "def simple_method(a, b, c=1, *args)
                @a = 34
              end"

    @inspector.analyze source
    expect(@inspector.processed_ast).to be_a_kind_of(DefNode)
    def_node = @inspector.processed_ast
    expect(def_node.method_name).to eq(:simple_method)
    expect(def_node.arguments).to be_a_kind_of(ArgsNode)
    expect(def_node.arguments.args.length).to eq(4)
    expect(def_node.raw_astbody).to eq(s(:ivasgn, :@a, s(:int, 34)))
    expect(def_node.body).to be_a_kind_of(IVasgnNode)
  end

  it 'inspect multiple def declarations' do
    source = "def bleh(a)
                  3 - a
                  45
                end"
    @inspector.analyze source
    expect(@inspector.processed_ast).to be_a_kind_of(DefNode)
    def_node = @inspector.processed_ast
    expect(def_node.body).to be_a_kind_of(BlockNode)
    expect(def_node.body.nodes.length).to eq(2)
  end

  it 'inspect def with begin/rescue' do
    source = "def another_method(a)
                  begin
                    3 - a
                    45
                  rescue Exception => e
                    puts e.message
                  end
                  2
                end"
    @inspector.analyze source
    puts p @inspector.raw_ast
    puts @inspector.processed_ast
  end
end