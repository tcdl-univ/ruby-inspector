require 'parser/current'
require_relative 'common'

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