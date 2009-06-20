.tst.desc["Option Parsing"]{
  before{
    / Null mocks so that variables assigned by option parser are automatically reset
    `a mock `;
    `.utl.args mock ("--foo";"10";"--baz";"trade";"--hello";"--bar=20090620";"--bat";"10 20 30";"--qux";"f o o");
    };
  should["support option/value pairs separated by spaces"]{
    .utl.addOpt["foo";"I";`a];
    a musteq 10;
    };
  should["support option/value pairs separated by an equals sign"]{
    .utl.addOpt["bar";"I";`a];
    a musteq 20090620;
    };
  should["let multiple options be parsed by the same parser"]{
    .utl.addOpt["foo,bar";"I";`a];
    a mustin (10;20090620);
    };
  should["interpret options with a type of a single character as a single value cast to that type"]{
    .utl.addOpt["foo";"I";`a];
    a musteq 10;
    .utl.addOpt["baz";"S";`a];
    a musteq `trade
    };
  should["interpret options with a type of a character list as a list cast to the type of the first character"]{
    .utl.addOpt["bat";(),"I";`a];
    a musteq 10 20 30;
    .utl.addOpt["qux";(),"C";`a];
    a mustmatch "foo";
    };
  should["interpret options with a positive boolean as presence flags"]{
    .utl.addOpt["hello";1b;`a];
    a musteq 1b;
    };
  should["interpret options with a negative boolean as absence flags"]{
    .utl.addOpt["hello";0b;`a];
    a musteq 0b;
    };
  should["always call boolean callbacks if there is a variable to assign to"]{
    .utl.addOpt["hello";1b;`a];
    a musteq 1b;
    .utl.addOpt["goodbye";1b;`a];
    a musteq 0b;
    .utl.addOpt["goodbye";0b;(`a;{x+x})];
    a musteq 2;
    };
  should["only call boolean callbacks when the option is present if the callback is a function"]{
    .utl.addOpt["hello";1b;{`a set `on}];
    a musteq `on;
    .utl.addOpt["goodbye";1b;{`a set `off}];
    a musteq `on;
    };
  should["only call non-boolean callbacks when the option is present"]{
    mustthrow[();{.utl.addOpt["foo";"I";{'"error"}]}];
    mustnotthrow[();{.utl.addOpt["oof";"I";{'"error"}]}];
    };
  should["assign to the variable named when a symbol is the callback"]{
    .utl.addOpt["foo";"I";`a];
    a mustnmatch `;
    };
  should["invoke the function provided when a function is the callback"]{
    mustthrow[();{.utl.addOpt["foo";"I";{'"error"}]}];
    };
  should["invoke the function provided and assign the rsult to the variable named when a symbol/function pair is the callback"]{
    .utl.addOpt["foo";"I";(`a;2*)];
    a musteq 20;
    };
  should["raise an error if an unhandled option was present and no usage message was provided"]{
    mustthrow[();{.utl.opts.finalize[]}];
    };
  should["leave remaining arguments in .utl.args"]{
    .utl.addOpt["foo";"*";`a];
    .utl.addOpt["bar";"*";`a];
    .utl.addOpt["bat";"*";`a];
    .utl.addOpt["baz";"*";`a];
    .utl.addOpt["hello";1b;`a];
    count[.utl.args] musteq 2;
    "--qux" mustmatch .utl.args[0];
    "f o o" mustmatch .utl.args[1];
    };
  };
