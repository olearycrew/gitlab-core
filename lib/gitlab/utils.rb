# frozen_string_literal: true

module Gitlab
  module Utils
    extend self

    # Ensure that the relative path will not traverse outside the base directory
    def check_path_traversal!(path)
      raise StandardError.new("Invalid path") if path.start_with?("..#{File::SEPARATOR}") ||
          path.include?("#{File::SEPARATOR}..#{File::SEPARATOR}") ||
          path.end_with?("#{File::SEPARATOR}..")

      path
    end

    def force_utf8(str)
      str.dup.force_encoding(Encoding::UTF_8)
    end

    def ensure_utf8_size(str, bytes:)
      raise ArgumentError, 'Empty string provided!' if str.empty?
      raise ArgumentError, 'Negative string size provided!' if bytes.negative?

      truncated = str.each_char.each_with_object(+'') do |char, object|
        if object.bytesize + char.bytesize > bytes
          break object
        else
          object.concat(char)
        end
      end

      truncated + ('0' * (bytes - truncated.bytesize))
    end

    # Append path to host, making sure there's one single / in between
    def append_path(host, path)
      "#{host.to_s.sub(%r{\/+$}, '')}/#{path.to_s.sub(%r{^\/+}, '')}"
    end

    # A slugified version of the string, suitable for inclusion in URLs and
    # domain names. Rules:
    #
    #   * Lowercased
    #   * Anything not matching [a-z0-9-] is replaced with a -
    #   * Maximum length is 63 bytes
    #   * First/Last Character is not a hyphen
    def slugify(str)
      return str.downcase
        .gsub(/[^a-z0-9]/, '-')[0..62]
        .gsub(/(\A-+|-+\z)/, '')
    end

    # Converts newlines into HTML line break elements
    def nlbr(str)
      ActionView::Base.full_sanitizer.sanitize(+str, tags: []).gsub(/\r?\n/, '<br>').html_safe
    end

    def remove_line_breaks(str)
      str.gsub(/\r?\n/, '')
    end

    def to_boolean(value)
      return value if [true, false].include?(value)
      return true if value =~ /^(true|t|yes|y|1|on)$/i
      return false if value =~ /^(false|f|no|n|0|off)$/i

      nil
    end

    def boolean_to_yes_no(bool)
      if bool
        'Yes'
      else
        'No'
      end
    end

    def random_string
      Random.rand(Float::MAX.to_i).to_s(36)
    end

    # See: http://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
    # Cross-platform way of finding an executable in the $PATH.
    #
    #   which('ruby') #=> /usr/bin/ruby
    def which(cmd, env = ENV)
      exts = env['PATHEXT'] ? env['PATHEXT'].split(';') : ['']

      env['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each do |ext|
          exe = File.join(path, "#{cmd}#{ext}")
          return exe if File.executable?(exe) && !File.directory?(exe)
        end
      end

      nil
    end

    def try_megabytes_to_bytes(size)
      Integer(size).megabytes
    rescue ArgumentError
      size
    end

    def bytes_to_megabytes(bytes)
      bytes.to_f / Numeric::MEGABYTE
    end

    # Used in EE
    # Accepts either an Array or a String and returns an array
    def ensure_array_from_string(string_or_array)
      return string_or_array if string_or_array.is_a?(Array)

      string_or_array.split(',').map(&:strip)
    end

    def deep_indifferent_access(data)
      if data.is_a?(Array)
        data.map(&method(:deep_indifferent_access))
      elsif data.is_a?(Hash)
        data.with_indifferent_access
      else
        data
      end
    end

    def string_to_ip_object(str)
      return unless str

      IPAddr.new(str)
    rescue IPAddr::InvalidAddressError
    end

    # Inverse of `Hash#dig` - sets a value in a Hash
    # by assigning a deep path of keys, vivifying any intermediate
    # hashes that are required.
    #
    # Useful if you need multi-dimensional hashes.
    #
    # e.g:
    #   hash = {}
    #   Gitlab::Utils.set_in(hash, %i[a b c], 10)
    #   expect(hash.dig(:a, :b, :c)).to eq(10)
    #
    def set_in(hash, keys, value)
      if keys.present?
        keys = keys.dup
        h = hash
        last_key = keys.pop
        keys.each do |k|
          h = (h[k] ||= {})
        end
        h[last_key] = value
      end

      hash
    end

    # Similar to Array#index_by, except that it takes an array of
    # key functions, and indexes by a mult-dimensional key.
    #
    # Symbols are promoted to Procs
    #
    # e.g:
    #   h = index_by_multikey(%w[word worm work waste], :first, :size, :last)
    #   => {
    #        'w' => {
    #          3 => { 'd' => 'word', 'm' => 'worm', 'k' => 'work' },
    #          5 => { 'e' => 'waste' }
    #        }
    #      }
    #   h.dig('w', 3, 'm') === 'worm'
    #
    def index_by_multikey(collection, *key_fns)
      key_fns = key_fns.map { |k| k.is_a?(Symbol) ? k.to_proc : k }

      collection.each_with_object({}) do |item, hash|
        key = key_fns.map { |k| k[item] }
        set_in(hash, key, item)
      end
    end

    # Create a new hash that allows deep setting of keys
    #
    # Be careful when using an AutovivifyingHash - it should only be indexed
    # using `#dig` to avoid accidentally creating intermediate keys.
    #
    # e.g.:
    #   hash = autovivifying_hash
    #   hash[:a][:b][:c] = 10
    #   expect(hash.dig(:a, :b, :c)).to eq(10)
    #   expect(hash.dig(:a, :x, :c)).to be_nil
    def autovivifying_hash
      AutovivifyingHash.new { |h, k| h[k] = autovivifying_hash }
    end

    # Support class - only calls `[key]` if the key is present, avoiding
    # any autovivifying behaviour when digging.
    class AutovivifyingHash < Hash
      def dig(key, *keys)
        if has_key?(key)
          super
        else
          nil
        end
      end
    end
  end
end
