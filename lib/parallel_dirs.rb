#!/usr/bin/ruby -w
# vi: set fileencoding=utf-8

=begin
parallel_dirs - 複数の対応付けられたディレクトリをもつクロージャを返す。
クロージャは1個の引数（対応付けられたディレクトリのいずれかの下にある任意のパス。相対パスでも可）を受け取り、
[ 引数で指定したパスのフルパス, 引数で指定したパスに対応するパス, ... ]
を返す
実行例
get_dirs = parallel_dirs( *%w[ /home/foo /media/disk /media/disk-1 ] ) #末尾のスラッシュはなしにすべし。
Dir.chdir '/home/foo/'
#出力の順番は、1番目をのぞき、不定
get_dirs[ 'bar' ] #=>[ '/home/foo', '/media/disk/bar', '/media/disk-1/bar' ]
get_dirs[ '/media/disk/file' ] #=>[ '/media/disk', '/home/foo/file', /media/disk-1/file' ]
#「対応付けられたディレクトリ」の中にないパスを指定した場合、nil
get_dirs[ '/not_contained/' ] #=>nil
=end

def parallel_dirs(*root_dirs)
  rdirs = root_dirs.find_all {|dir| File.directory? dir } #rdirs: root directrotries( existing )
  if rdirs.length <= 1
    raise( ArgumentError, "\n" +
        "  No directories can be the destination!\n" +
        "  This function needs 2 or more existing directories specified in the arguments.\n" +
        "  the arguments you specified:\n" +
        "    " +
        root_dirs.join("\n    ")
    )
  end
  lambda do|spath|
    ###同期元のパス###
    abs_spath = File.expand_path( spath ) #absolute source path
    #srdir: source root directory (要素は1個のみであるべき), drdirs: destination root directories
    srdir, drdirs = rdirs.partition do|rd|
      abs_spath.index(rd) == 0 #abs_spathで始まるrd*以外*が、同期*先*のルートディレクトリになる
    end
    return if srdir.empty?

    ###同期元のルートディレクトリを調べ、それを元に同期先のルートディレクトリの配列を作る###
    ###同期先のパス（の配列）###
    #abs_spathの最初のsrdir[0]の部分をrdirに変換した配列が、同期先のパスになる
    [ abs_spath, *drdirs.map {|drdir| abs_spath.sub( /^#{Regexp.escape(srdir[0])}/o, drdir ) } ]
  end
end
