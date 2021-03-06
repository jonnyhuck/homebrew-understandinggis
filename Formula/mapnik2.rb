class Mapnik2 < Formula
  desc "Toolkit for developing mapping applications"
  homepage "http://www.mapnik.org/"
#   url "https://s3.amazonaws.com/mapnik/dist/v2.2.0/mapnik-v2.2.0.tar.bz2"
  url "https://github.com/jonnyhuck/homebrew-understandinggis/blob/master/Download/mapnik-v2.2.0.tar.bz2?raw=true"
  sha256 "9b30de4e58adc6d5aa8478779d0a47fdabe6bf8b166b67a383b35f5aa5d6c1b0"
  revision 2

  bottle do
    sha256 "d493b3dba9a41b2df14d3a5c527ceff127b0817bdac6df66ffd30addd5585f94" => :el_capitan
    sha256 "45df69d1334b448a551268d8ab73e7c5a1fa28645952cad91a1d8249616afdda" => :yosemite
    sha256 "e7ef76e01de18b3eeb866a801e23dd5630145e0f34968671741d0c30c7bffbf0" => :mavericks
  end

  # compile error in bindings/python/mapnik_text_placement.cpp
  # https://github.com/mapnik/mapnik/issues/1973
  patch :DATA

  # boost 1.56 compatibility
  # concatenated from https://github.com/mapnik/mapnik/issues/2428
  patch do
    url "https://gist.githubusercontent.com/tdsmith/22aeb0bfb9691de91463/raw/3064c193466a041d82e011dc5601312ccadc9e15/mapnik-boost-megadiff.diff"
    sha256 "40e83052ae892aa0b134c09d8610ebd891619895bb5f3e5d937d0c48ed42d1a6"
  end

  depends_on "pkg-config" => :build
  depends_on "freetype"
  depends_on "libpng"
  depends_on "libtiff"
  depends_on "proj"
  depends_on "icu4c"
  depends_on "jpeg"
  depends_on "boost159"
  depends_on "boost-python159"
  depends_on "gdal" => :optional
  depends_on "postgresql" => :optional
  depends_on "cairo" => :optional
  depends_on "py2cairo" if build.with? "cairo"

  conflicts_with "mapnik", :because => "Differing versions of the same formula"

  def install
    icu = Formula["icu4c"].opt_prefix
    boost = Formula["boost159"].opt_prefix
    proj = Formula["proj"].opt_prefix
    jpeg = Formula["jpeg"].opt_prefix
    libpng = Formula["libpng"].opt_prefix
    libtiff = Formula["libtiff"].opt_prefix
    freetype = Formula["freetype"].opt_prefix

    # mapnik compiles can take ~1.5 GB per job for some .cpp files
    # so lets be cautious by limiting to CPUS/2
    jobs = ENV.make_jobs.to_i
    jobs /= 2 if jobs > 2
    
    # "ICU_LIB_NAME=#{}icu4c", JJH added this - unsuccessful
    args = ["CC=\"#{ENV.cc}\"",
            "CXX=\"#{ENV.cxx}\"",
            "JOBS=#{jobs}",
            "PREFIX=#{prefix}",
            "ICU_INCLUDES=#{icu}/include",
            "ICU_LIBS=#{icu}/lib",
            "PYTHON_PREFIX=#{prefix}", # Install to Homebrew's site-packages
            "JPEG_INCLUDES=#{jpeg}/include",
            "JPEG_LIBS=#{jpeg}/lib",
            "PNG_INCLUDES=#{libpng}/include",
            "PNG_LIBS=#{libpng}/lib",
            "TIFF_INCLUDES=#{libtiff}/include",
            "TIFF_LIBS=#{libtiff}/lib",
            "BOOST_INCLUDES=#{boost}/include",
            "BOOST_LIBS=#{boost}/lib",
            "PROJ_INCLUDES=#{proj}/include",
            "PROJ_LIBS=#{proj}/lib",
            "FREETYPE_CONFIG=#{freetype}/bin/freetype-config",
           ]

    if build.with? "cairo"
      args << "CAIRO=True" # cairo paths will come from pkg-config
    else
      args << "CAIRO=False"
    end
    args << "GDAL_CONFIG=#{Formula["gdal"].opt_bin}/gdal-config" if build.with? "gdal"
    args << "PG_CONFIG=#{Formula["postgresql"].opt_bin}/pg_config" if build.with? "postgresql"

    print args
    
    #system "python", "scons/scons.py", "configure", *args
    #system "python", "scons/scons.py", "install"
    system "/usr/local/bin/python", "scons/scons.py", "configure", *args
    system "/usr/local/bin/python", "scons/scons.py", "install"
    
  end

  test do
    system bin/"mapnik-config", "-v"
  end
end

__END__
diff --git a/bindings/python/mapnik_text_placement.cpp b/bindings/python/mapnik_text_placement.cpp
index 0520132..4897c28 100644
--- a/bindings/python/mapnik_text_placement.cpp
+++ b/bindings/python/mapnik_text_placement.cpp
@@ -194,7 +194,11 @@ struct ListNodeWrap: formatting::list_node, wrapper<formatting::list_node>
     ListNodeWrap(object l) : formatting::list_node(), wrapper<formatting::list_node>()
     {
         stl_input_iterator<formatting::node_ptr> begin(l), end;
-        children_.insert(children_.end(), begin, end);
+        while (begin != end)
+        {
+            children_.push_back(*begin);
+            ++begin;
+        }
     }

     /* TODO: Add constructor taking variable number of arguments.
