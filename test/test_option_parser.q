.tst.desc["Option Parsing"]{
  before{
    / Null mocks so that variables assigned by option parser are automatically reset
    `a mock `;
    `.utl.arg.outHandle mock {};
    `.utl.arg.exit mock {};
    `.utl.arg.boolOpts mock ();
    `.utl.arg.regOpts mock ();
    `.utl.arg.regDefOpts mock ();
    `.utl.arg.posArgs mock ();
    `.utl.arg.args mock ("10";"--foo";"10";"--baz";"trade";"--hello";"20";"--bar=20090620";"--bat";"10 20 30";"--qux";"f o o";"--bat-bar";"--bat-boo");
    `.utl.arg.handleUnrecognized mock {}; / Need to turn this off for partial option testing
    `.utl.arg.handleUnrecognizedBackup mock .utl.arg.handleUnrecognized; 
    };
  should["support option/value pairs separated by spaces"]{
    .utl.addOpt["foo";"I";`a];
    .utl.parseArgs[];
    a musteq 10;
    };
  should["support option/value pairs separated by an equals sign"]{
    .utl.addOpt["bar";"I";`a];
    .utl.parseArgs[];
    a musteq 20090620;
    };
  should["support boolean options with a dash in the option name"]{
    `b mock `;
    .utl.addOpt["bbo,bat-boo";1b;`a];
    .utl.addOpt["bba,bat-bar";1b;`b];
    .utl.parseArgs[];
    a mustmatch 1b;
    b mustmatch 1b;
    };
  should["let multiple options be parsed by the same parser"]{
    .utl.addOpt["foo,bar";"I";`a];
    .utl.parseArgs[];
    a mustin (10;20090620);
    };
  should["interpret options with a type of a single character as a single value cast to that type"]{
    .utl.addOpt["foo";"I";`a];
    .utl.parseArgs[];
    a musteq 10;
    .utl.addOpt["baz";"S";`a];
    .utl.parseArgs[];
    a musteq `trade
    };
  should["throw an error if a default value option is given a boolean option type"]{
    mustthrow[();{.utl.addOptDef["foo";1b;0b;`foo];}];
    };
  should["run a default value option whether the option is present or not"]{
    .utl.addOptDef["foo";"I";1;{`a set 1}];
    .utl.parseArgs[];
    a mustmatch 1;
    `.utl.arg.args mock ();
    .utl.addOptDef["foo";"I";1;{`a set 2}];
    .utl.parseArgs[];
    a mustmatch 2;
    };
  should["use default option value when the option is not present"]{
    `.utl.arg.args mock ();
    `foo mock 0N;
    .utl.addOptDef["foo";"I";1;`foo];
    .utl.parseArgs[];
    foo musteq 1;
    };
  should["interpret options with a type of a character list as a list cast to the type of the first character"]{
    .utl.addOpt["bat";(),"I";`a];
    .utl.parseArgs[];
    a musteq 10 20 30;
    .utl.addOpt["qux";(),"C";`a];
    .utl.parseArgs[];
    a mustmatch "foo";
    };
  should["interpret options with a positive boolean as presence flags"]{
    .utl.addOpt["hello";1b;`a];
    .utl.parseArgs[];
    a musteq 1b;
    };
  should["interpret options with a negative boolean as absence flags"]{
    .utl.addOpt["hello";0b;`a];
    .utl.parseArgs[];
    a musteq 0b;
    };
  should["always call boolean callbacks if there is a variable to assign to"]{
    .utl.addOpt["hello";1b;`a];
    .utl.parseArgs[];
    a musteq 1b;
    .utl.addOpt["goodbye";1b;`a];
    .utl.parseArgs[];
    a musteq 0b;
    .utl.addOpt["goodbye";0b;(`a;{x+x})];
    .utl.parseArgs[];
    a musteq 2;
    };
  should["only call boolean callbacks when the option is present if the callback is a function"]{
    .utl.addOpt["hello";1b;{`a set `on}];
    .utl.parseArgs[];
    a musteq `on;
    .utl.addOpt["goodbye";1b;{`a set `off}];
    .utl.parseArgs[];
    a musteq `on;
    };
  should["only call non-boolean callbacks when the option is present"]{
    .utl.addOpt["foo";"I";{`a set 1}];
    .utl.parseArgs[];
    a mustmatch 1;
    `.utl.arg.regOpts mock ();
    .utl.addOpt["oof";"I";{`a set 2}];
    .utl.parseArgs[];
    a mustmatch 1;
    };
  should["assign to the variable named when a symbol is the callback"]{
    .utl.addOpt["foo";"I";`a];
    .utl.parseArgs[];
    a mustnmatch `;
    };
  should["invoke the function provided when a function is the callback"]{
    .utl.addOpt["foo";"I";{`a set 1}];
    .utl.parseArgs[];
    a mustmatch 1;
    };
  should["invoke the function provided and assign the result to the variable named when a symbol/function pair is the callback"]{
    .utl.addOpt["foo";"I";(`a;2*)];
    .utl.parseArgs[];
    a musteq 20;
    };
  should["raise an error if an unhandled option was present and no usage message was provided"]{
    mustthrow[();{.utl.opts.finalize[]}];
    };
  should["call .utl.arg.exit if there are arguments remaining in .utl.arg.args"]{
    `.utl.arg.exit mock {'"exit"};
    .utl.addOpt["foo";"*";`a];
    .utl.addOpt["bar";"*";`a];
    .utl.addOpt["bat";"*";`a];
    .utl.addOpt["baz";"*";`a];
    .utl.addOpt["hello";1b;`a];
    mustthrow["exit";{.utl.parseArgs[];}];
    };
  should["require the specified number of positional arguments"]{
    .utl.arg.args:("10";"20");
    `.utl.arg.exit mock {'"error"};
    .utl.addArg["I";();2;`a];
    mustnotthrow[();{.utl.parseArgs[];}];
    .utl.arg.posArgs:();
    a mustmatch 10 20;
    .utl.addArg["I";();1;`a];
    mustthrow[();{.utl.parseArgs[];}];
    };
  should["use the default value provided when a positional argument is absent"]{
    .utl.arg.args:("10";"20");
    .utl.addArg["I";1;2;`a];
    .utl.addArg["I";3;0;`a];
    mustnotthrow[();{.utl.parseArgs[];}];
    a mustmatch 3;
    };
  should["accept default values that are lists"]{
    .utl.arg.args:();
    `.utl.arg.exit mock {'"error"};
    `b mock ();
    .utl.addArg["I";2 3;0;`a];
    .utl.addOptDef["foo";(),"I";1 2;`b];
    mustnotthrow[();{.utl.parseArgs[];}];
    a mustmatch 2 3;
    b mustmatch 1 2;
    `.utl.arg.posArgs mock ();
    .utl.arg.args: enlist "--help"; / Force output to print, which seemed to be causing an error
    `.utl.arg.outHandle mock {10h mustmatch type x};
    mustthrow["error";{.utl.parseArgs[];}];
    };
  should["raise an error if a positional argument is absent and there is no default"]{
    .utl.arg.args:("10";"20");
    `.utl.arg.exit mock {'"error"};
    .utl.addArg["I";();2;`a];
    mustnotthrow[();{.utl.parseArgs[];}];
    .utl.arg.posArgs:();
    .utl.addArg["I";();1;`a];
    mustthrow[();{.utl.parseArgs[];}];
    };
  should["handle positional arguments intermixed with optional arguments"]{
    `b`c`d`e mock' `;
    .utl.addOpt["foo";"I";`a];
    .utl.addArg["I";();1;`b];
    .utl.addArg["I";();1;`c];
    .utl.addOpt["baz";"S";`d];
    .utl.addOpt["hello";1b;`e];
    .utl.parseArgs[];
    a mustmatch 10;
    b mustmatch 10;
    c mustmatch 20;
    d mustmatch `trade;
    e mustmatch 1b;
    };
  should["consume remaining arguments when the number of arguments handled is enlisted"]{
    .utl.arg.args:("10";"20");
    .utl.addArg["I";();1,();`a];
    .utl.parseArgs[];
    a mustmatch 10 20;
    .utl.arg.args mustmatch ();
    };
  should["process all remaining arguments properly when the number of arguments to be handled is zero or the remaining arguments"]{
    .utl.arg.args:("10";"20");
    .utl.addArg["I";10;0,();`a];
    .utl.parseArgs[];
    a mustmatch 10 20;
    `.utl.arg.posArgs mock ();
    .utl.arg.args:enlist ("10");
    .utl.addArg["I";10;0,();`a];
    .utl.parseArgs[];
    a mustmatch enlist 10;
    `a mock 0;
    `.utl.arg.posArgs mock ();
    .utl.arg.args:enlist ("10");
    .utl.addArg["I";0;0;`a];
    .utl.parseArgs[];
    a mustmatch 10;
    `b mock 0;
    `a mock 0;
    `.utl.arg.posArgs mock ();
    .utl.arg.args:("10";"20");
    .utl.addArg["I";0;0;`a];
    .utl.addArg["I";0;0;`b];
    .utl.parseArgs[];
    a mustmatch 10;
    b mustmatch 20;
    };
  should["use the default argument value when no positional arguments are present and the number of arguments to be handled is zero or one"]{
    .utl.arg.args:();
    .utl.addArg["S";`foo;0;`a];
    .utl.parseArgs[];
    a mustmatch `foo;
    `.utl.arg.posArgs mock ();
    .utl.arg.args:enlist "baz";
    .utl.addArg["S";`foo;0;`a];
    .utl.parseArgs[];
    a mustmatch `baz;
    `.utl.arg.posArgs mock ();
    `b mock ();
    .utl.arg.args:("--help";"21";"baz");
    .utl.addArg["S";`foo;0;`a];
    .utl.addOptDef["help";"I";10;`b];
    .utl.parseArgs[];
    a mustmatch `baz;
    b mustmatch 21;
    `.utl.arg.posArgs mock ();
    `.utl.arg.regDefOpts mock ();
    `b mock ();
    `c mock ();
    .utl.arg.args:("baz";"--help";"21";"bat";"boo");
    .utl.addArg["S";`foo;0;`a];
    .utl.addOptDef["help";"I";10;`b];
    .utl.addArg["S";`bat`blah;0,();`c];
    .utl.parseArgs[];
    a mustmatch `baz;
    b mustmatch 21;
    c mustmatch `bat`boo;
    };
  should["treat arguments taking exactly 1 value as atoms and all others as lists"]{
    `b mock `;
    .utl.arg.args:("10";"20");
    .utl.addArg["I";();1;`a];
    .utl.addArg["I";();1,();`b];
    .utl.parseArgs[];
    a mustmatch 10;
    b mustmatch (),20;
    };
  };
