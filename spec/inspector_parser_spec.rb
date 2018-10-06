require_relative '../lib/ruby-inspector/static/inspector_ast'
require 'ast/sexp'

describe 'Ruby::AST' do
  include AST::Sexp

  it 'parse invalid syntax source' do
    source = "defe meh
                      34 -1 + a
                     end"

    parser = InspectorParser.new
    expect { parser.parse_source(source) }.to raise_exception(InspectorException)
  end

  it 'parse valid method definition' do
    source = "def something(a, b, c=0)
               a + b * c
               end"
    parser = InspectorParser.new
    ast = parser.parse_source source
    expect(ast).to eq(s(:def, :something, s(:args, s(:arg, :a), s(:arg, :b), s(:optarg, :c, s(:int, 0))), s(:send, s(:lvar, :a), :+, s(:send, s(:lvar, :b), :*, s(:lvar, :c)))))
    expect(ast.to_s).to eq("(def :something\n  (args\n    (arg :a)\n    (arg :b)\n    (optarg :c\n      (int 0)))\n  (send\n    (lvar :a) :+\n    (send\n      (lvar :b) :*\n      (lvar :c))))")
    expect(ast.type).to eq(:def)
  end

  it 'parse valid class definition' do
    source = "class A
               def something
                  42
               end
              end"
    parser = InspectorParser.new
    ast = parser.parse_source source
    expect(ast).to eq(s(:class, s(:const, nil, :A), nil, s(:def, :something, s(:args), s(:int, 42))))
    expect(ast.type).to eq(:class)
  end
end