require 'liquid'

# This is a file system that removes Liquid's security measures
# that put a restriction on file names. This allows us to use the
# converted files from the prototype. This is copied verbatim from
# the Liquid source but with the path check removed.
class BodgeFileSystem < Liquid::LocalFileSystem
  def full_path template_path
    full_path = if template_path.include?('/'.freeze)
      File.join(root, File.dirname(template_path), @pattern % File.basename(template_path))
    else
      File.join(root, @pattern % template_path)
    end

    raise FileSystemError, "Illegal template path '#{File.expand_path(full_path)}'" unless File.expand_path(full_path).start_with?(File.expand_path(root))

    full_path
  end
end