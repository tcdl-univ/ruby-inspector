require_relative '../static/inspector_ast'

class DynamicInspector

  attr_accessor :parser, :ast_processor, :original_ast_code, :ast, :parsed, :original_parsed_code

  def initialize
    self.parser = InspectorParser.new
    self.ast_processor = InspectorAST.new
  end

  def process_code(code)
    self.original_parsed_code = self.parser.parse_source code
    self.original_ast_code = self.ast_processor.analyze code
    self.parsed = self.original_parsed_code
    self.ast = self.original_ast_code
  end

  def transform_code(code, fixture)
    self.process_code(code)

  end

end