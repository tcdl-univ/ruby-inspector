require 'parser/current'

class InspectorException < StandardError
end

class InspectorParser
  attr_accessor :ast, :parser, :diagnostics

  def initialize
    self.reset_inspector
  end

  def reset_inspector
    self.diagnostics = []
    self.parser = Parser::CurrentRuby.new
  end

  def parse_source(source_code, cleanup= false)
    begin
      parser.diagnostics.consumer = lambda do |diagnostic|
        self.diagnostics << diagnostic
      end

      buffer = Parser::Source::Buffer.new '(string)'
      buffer.source = source_code

      self.ast = self.parser.parse buffer
      self.report_diagnostics

      if cleanup
        #clean the inspector state
        self.reset_inspector
      end

      return self.ast

    rescue Parser::SyntaxError => e
      raise InspectorException.new e
    end
  end

  def report_diagnostics
    unless self.diagnostics.empty?
      DiagnosticsReporter.new.report self.diagnostics
    end
  end
end

class DiagnosticsReporter
  def report(diagnostics)
    diagnostics.each do |diagnostic|
      puts diagnostic.render
    end
  end
end

class Inspector

  attr_accessor :parser, :raw_ast, :processed_ast

  def initialize
    self.parser = InspectorParser.new
    self.processed_ast = []
  end

  def analyze(source_code)
    self.raw_ast = self.parser.parse_source source_code
    self.analyze_ast
  end

  def analyze_ast
    self.processed_ast = self.dispatch_type self.raw_ast
  end

  def dispatch_type(ast)
    self.send "process_#{ast.type}".to_sym, ast
  end

  def process_inner_block(ast)
    self.dispatch_type(ast)
  end

  def process_block(ast)

  end

  def process_arguments(ast)
    node = ArgsNode.new
    arg_list = *ast.children
    arg_list.each do |arg|
      node.args << self.dispatch_type(arg)
    end
    node
  end

  def process_generic_node(ast, node_type)
    node = node_type.new *ast.children
    node
  end

  def process_int(ast)
    self.process_generic_node ast, IntNode
  end

  def process_optarg(ast)
    self.process_generic_node ast, OptArgument
  end

  def process_arg(ast)
    self.process_generic_node ast, ArgumentNode
  end

  def process_restarg(ast)
    self.process_generic_node ast, RestArguments
  end

  def process_ivasgn(ast)
    self.process_generic_node ast, IVasgnNode
  end

  def process_send(ast)
    self.process_generic_node ast, SendMessageNode
  end

  def process_lvar(ast)
    self.process_generic_node ast, LocalVariable
  end

  def process_def(ast)
    method_name, arguments, body_ast = *ast.children
    arguments_node = self.process_arguments arguments
    body = self.process_inner_block body_ast
    node = DefNode.new method_name, arguments_node, body_ast
    node.body = body
    node
  end

  def process_begin(ast)
    block_node = BlockNode.new
    ast.children.to_a.each do |ast_node|
      node = self.dispatch_type ast_node
      block_node.nodes << node
    end
    block_node
  end

end


class BasicNode
  attr_accessor :raw_ast
end

class IntNode < BasicNode
  attr_accessor :value

  def initialize value
    self.value = value
  end

end

class IVasgnNode < BasicNode
  attr_accessor :symbol, :value

  def initialize symbol, value_ast
    self.symbol = symbol
    inner_inspector = Inspector.new
    value_node = inner_inspector.dispatch_type value_ast
    self.value = value_node.value
  end
end

class LocalVariable < BasicNode
  attr_accessor :symbol

  def initialize symbol
    self.symbol = symbol
  end
end

class ArgsNode < BasicNode
  attr_accessor :args

  def initialize
    self.args = []
  end
end

class ArgumentNode < BasicNode
  attr_accessor :name

  def initialize argument_name
    self.name = argument_name
  end
end


class RestArguments < ArgumentNode
end

class OptArgument < ArgumentNode
  attr_accessor :default_value

  def initialize argument_name, value
    super argument_name
    inner_inspector = Inspector.new
    value_node = inner_inspector.dispatch_type value
    self.default_value = value_node.value
  end
end

class SendMessageNode < BasicNode
  attr_accessor :message, :receptor, :emissor

  def initialize emissor_ast, message, receptor_ast
    self.message = message
    inner_inspector = Inspector.new
    self.emissor = inner_inspector.dispatch_type emissor_ast
    self.receptor = inner_inspector.dispatch_type receptor_ast
  end
end

class DefNode < BasicNode
  attr_accessor :method_name, :raw_astbody, :arguments, :body

  def initialize method_name, arguments_node, raw_astbody
    self.method_name = method_name
    self.arguments = arguments_node
    self.raw_astbody = raw_astbody
  end

end

class BlockNode < BasicNode
  attr_accessor :nodes

  def initialize
    self.nodes = []
  end
end