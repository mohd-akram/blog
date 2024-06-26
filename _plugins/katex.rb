require 'katex'

module KatexPlugin
    class KatexFile < Jekyll::StaticFile
        def initialize(site, dir, name)
            super(site, Katex.gem_path, File.join('vendor', 'katex', dir), name)
        end
        def destination(dest)
            p = @dir
            if File.basename(p) == 'stylesheets'
                p = File.dirname(p)
            end
            File.join(dest, 'assets', p, @name)
        end
    end

    class KatexDir
        def initialize(dir)
            @dir = dir
        end

        def self.[](dir)
            new(dir)
        end

        def files(site)
            Dir.children(File.join(Katex.gem_path, 'vendor', 'katex', @dir)).map do |file|
                KatexFile.new(site, @dir, file)
            end
        end
    end

    class Generator < Jekyll::Generator
        def generate(site)
            site.static_files.concat(
                KatexDir['stylesheets'].files(site),
                KatexDir['fonts'].files(site)
            )
        end
    end
end
