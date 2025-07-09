class ClaudeTools < Formula
  desc "Claude Code advanced workflow system with Git worktree, design iteration, and IDE integration"
  homepage "https://github.com/angelor888/DR-IT-ClaudeSDKSetup"
  url "https://github.com/angelor888/DR-IT-ClaudeSDKSetup/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "PLACEHOLDER_SHA256"
  license "PROPRIETARY"
  version "1.0.0"

  depends_on "node"
  depends_on "git"
  depends_on "jq"
  depends_on "docker"

  def install
    # Install all files to libexec
    libexec.install Dir["*"]
    
    # Make scripts executable
    system "chmod", "+x", "#{libexec}/install.sh"
    system "chmod", "+x", "#{libexec}/uninstall.sh"
    system "chmod", "+x", "#{libexec}/claude-config/scripts/*.sh"
    system "chmod", "+x", "#{libexec}/scripts/*.sh"
    
    # Create bin wrappers
    (bin/"claude-workflow-install").write_env_script libexec/"install.sh", {}
    (bin/"claude-workflow-uninstall").write_env_script libexec/"uninstall.sh", {}
    
    # Install shell integration
    (prefix/"shell-integration.sh").write <<~EOS
      #!/bin/bash
      # Claude Tools Homebrew Integration
      export CLAUDE_TOOLS_ROOT="#{libexec}"
      source "#{libexec}/claude-config/shell-integration.sh"
    EOS
  end

  def post_install
    puts ""
    puts "🚀 Claude Tools installed successfully!"
    puts ""
    puts "To complete the installation:"
    puts "  1. Run: claude-workflow-install"
    puts "  2. Add to your shell profile:"
    puts "     echo 'source #{prefix}/shell-integration.sh' >> ~/.zshrc"
    puts "  3. Restart your terminal or: source ~/.zshrc"
    puts ""
    puts "Quick start commands:"
    puts "  claude-workflow-install     # Complete installation"
    puts "  cwt-create feature-name     # Create git worktree"
    puts "  cdesign 'UI brief'          # Generate design iterations"
    puts "  claude-mode model opus      # Switch to Claude Opus"
    puts ""
    puts "Documentation: #{homepage}"
  end

  def uninstall_postflight
    puts ""
    puts "🧹 Cleaning up Claude Tools..."
    puts ""
    
    # Remove configuration directory
    config_dir = "#{ENV["HOME"]}/.config/claude"
    if Dir.exist?(config_dir)
      puts "Removing configuration directory: #{config_dir}"
      FileUtils.rm_rf(config_dir)
    end
    
    # Remove from shell profiles
    shell_profiles = ["#{ENV["HOME"]}/.zshrc", "#{ENV["HOME"]}/.bashrc"]
    shell_profiles.each do |profile|
      next unless File.exist?(profile)
      
      content = File.read(profile)
      updated_content = content.gsub(/# Claude Tools Homebrew Integration\n.*shell-integration\.sh.*\n/, "")
      
      if content != updated_content
        File.write(profile, updated_content)
        puts "Removed from #{profile}"
      end
    end
    
    puts "✅ Claude Tools uninstalled successfully"
  end

  test do
    # Test that the installation script exists and is executable
    assert_predicate libexec/"install.sh", :exist?
    assert_predicate libexec/"install.sh", :executable?
    
    # Test that the package validation script works
    assert_predicate libexec/"validate-package-readiness.sh", :exist?
    assert_predicate libexec/"validate-package-readiness.sh", :executable?
    
    # Test that core directories exist
    assert_predicate libexec/"claude-config", :exist?
    assert_predicate libexec/"claude-config/scripts", :exist?
    assert_predicate libexec/"scripts", :exist?
    
    # Test that main scripts are executable
    assert_predicate libexec/"claude-config/scripts/claude-workflow-test.sh", :executable?
    assert_predicate libexec/"claude-config/scripts/claude-worktree.sh", :executable?
    
    puts "✅ All tests passed!"
  end
end