.tst.desc["A Config Parser"]{
  before{
    `configFile mock {.tst.testFilePath `configs,x};
    };
  should["handle name substitution in values"]{
    cfg: .utl.parseConfig configFile `nameSubstitution;
    cfg["first";"bar"] mustmatch "banana/grape";
    cfg["first";"bat"] mustmatch "banana";
    cfg["first";"qux"] mustmatch "orange";
    };
  should["fill missing values from a DEFAULT section if available"]{
    cfg: .utl.parseConfig configFile `default;
    cfg["foo";"baz"] mustmatch string 4;
    };
  };

.tst.desc["A Raw Config Parser"]{
  before{
    `configFile mock {.tst.testFilePath `configs,x};
    };
  should["parse files from handles"]{
    mustnotthrow[();{.utl.parseRawConfig configFile `normal}];
    };
  should["parse lists of char lists"]{
    cfg: read0 configFile `normal;
    mustnotthrow[();{[x;y]; .utl.parseRawConfig x}[cfg]];
    };
  should["support multiple sections"]{
    cfg: .utl.parseRawConfig configFile `multipleSections;
    ("foo";"bar") mustin key cfg;
    cfg["foo";"bar"] musteq string 2;
    cfg["foo";"baz"] musteq string 3;
    cfg["bar";"qux"] musteq string 5;
    };
  should["raise an error if there is not one section"]{
    mustthrow[();{.utl.parseRawConfig configFile `noSections}];
    };
  should["recognize colon as a name-value pair separator"]{
    mustnotthrow[();{.utl.parseRawConfig configFile `colonSeparators}];
    cfg: .utl.parseRawConfig configFile `colonSeparators;
    cfg["foo";"bar"] musteq string 2;
    cfg["foo";"baz"] musteq string 3;
    };
  should["recognize equals as a name-value pair separator"]{
    mustnotthrow[();{.utl.parseRawConfig configFile `equalsSeparators}];
    cfg: .utl.parseRawConfig configFile `equalsSeparators;
    cfg["foo";"bar"] musteq string 2;
    cfg["foo";"baz"] musteq string 3;
    };
  should["raise an error if there is an empty key"]{
    mustthrow[();{.utl.parseRawConfig configFile `emptyKey}];
    };
  should["handle RFC 822 style LONG HEADER FIELD continuations"]{
    cfg: .utl.parseRawConfig configFile `longHeader;
    cfg["foo";"bar"] mustmatch "1 2 3\t4";
    };
  should["remove leading whitespace from values"]{
    cfg: .utl.parseRawConfig configFile `leadingWhitespace;
    cfg["foo";"bar"] mustmatch string 1;
    cfg["foo";"baz"] mustmatch string 2;
    };
  should["ignore lines beginning with sharp"]{
    mustnotthrow[();{.utl.parseRawConfig configFile `sharpComment}];
    };
  should["ignore lines beginning with semi-colon"]{
    mustnotthrow[();{.utl.parseRawConfig configFile `semicolonComment}];
    };
  should["have the DEFAULT section in the raw configs if one was present"]{
    cfg: .utl.parseRawConfig configFile `normal; 
    "DEFAULT" mustin key cfg;
    };
  };
