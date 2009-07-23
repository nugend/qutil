.tst.desc["A Package Loader"]{
  before{
    `.utl.QPATH mock .tst.testFilePath `testLoaderFiles;
    `.utl.LOADED mock .utl.LOADED;
    };
  should["search the specified path location for packages"]{
    allFiles: 1 _' string key .utl.QPATH;
    count[.utl.requireVH.findV[;""] each allFiles] musteq count allFiles;
    };
  should["should not change the currently loading package when explicitly loading an individual file from a different package"]{
    / This is because despite the fact that a file is being loaded from a package, a different package is not actually being loaded
    `.utl.PKGLOADING mock "FOOBARBAZ";
    `verify mock {y mustmatch x}[.utl.PKGLOADING];
    .utl.require .tst.testFilePath `testLoaderFiles`verify_pkgloading.q
    };
  should["not load required files that have already been loaded"]{
    .utl.LOADED,: f:.tst.testFilePath `testLoaderFiles`verify_no_dup_require.q;
    mustnotthrow[();{[f;x].utl.require f}[f]];
    };
  should["be able to accept a file identifier that is a list of a symbol and a char list"]{
    mustnotthrow[();{.utl.require .tst.testFilePath[`testLoaderFiles`package],"verify_pkg_load.q"}];
    };
  should["be able to accept a file path to be loaded"]{
    mustnotthrow[();{.utl.require .tst.testFilePath`testLoaderFiles`verify_load_file_path.q}];
    };
  should["be able to accept a package name to be loaded"]{
    mustnotthrow[();{.utl.require "package"}];
    };
  };

.tst.desc["A Package Finder"]{
  before{
    `.utl.QPATH mock .tst.testFilePath `testLoaderFiles;
    `version mock "";
    `.utl.LOADED mock .utl.LOADED;
    };
  should["choose an exact package name match if the version string argument is empty"]{
    .utl.require "vpkg";
    version mustmatch "trunk";
    .utl.LOADED:();
    .utl.require "vpkg-0.1.2";
    version mustmatch "0.1.2";
    .utl.LOADED:();
    .utl.require "vpkg-1.2.1";
    version mustmatch "1.2.1";
    };
  should["choose the most recent matching version of a package if a version string has been supplied"]{
    .utl.requireV["vpkg";"<1.2"];
    version mustmatch "0.1.2";
    .utl.LOADED:();
    .utl.requireV["vpkg";"<2.2"];
    version mustmatch "1.2.1";
    .utl.LOADED:();
    .utl.requireV["vpkg";">0.5"];
    version mustmatch "1.2.1";
    .utl.LOADED:();
    };
  should["fallback to an exact package name match if there is no matching version"]{
    .utl.requireV["vpkg";">3.5"];
    version mustmatch "trunk";
    .utl.LOADED:();
    };
  };

.tst.desc["Version Numbers Utilities"]{
  should["compare version number strings properly"]{
    / cmpVNStr accepts value arguments in reverse order for internal ease of use
    cmp:{[op;v1;v2];must[.utl.requireVH.cmpVNStr[op;v2;v1];"Expected ", v1, " ", string[op], " ", v2]};
    cmp[<;"1";"2"];
    cmp[<;"1.0.0.20000";"2"];
    cmp[<;"2.200.9999";"3.0.0.1"];
    };
  should["compose a list of version strings into a multiple-version number comparison function"]{
    cmpF:{[vString;pth];must[.utl.requireVH.makeFilter[vString][pth];"Expected ", (1 _ string pth), " to pass the conditions: '", vString, "'"]};
    ncmpF:{[vString;pth];must[not .utl.requireVH.makeFilter[vString][pth];"Expected ", (1 _ string pth), " to fail the conditions: '", vString, "'"]};
    cmpF[">1.2,<2.3"] each hsym each `$("foo-1.2.1";"foo-1.3";"foo-1.7";"foo-2.2.10";"foo-2.2.9");
    ncmpF[">1.2,<2.3"] each hsym each `$("foo-1.1.9";"foo-1.2";"foo-1.2.0";"foo-2.3";"foo-2.3.0";"foo-2.4";"foo-3");
    };
  };
