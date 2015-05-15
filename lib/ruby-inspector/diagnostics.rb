class DiagnosticsReporter
  def report(diagnostics)
    diagnostics.each do |diagnostic|
      puts diagnostic.render
    end
  end
end