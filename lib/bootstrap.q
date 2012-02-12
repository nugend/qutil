.utl.LOADED:()
.utl.LOADING:`symbol$()
.utl.PKGSLOADED:enlist[""]!enlist[`:]
.utl.FILELOADING:`
.utl.PKGLOADING:""
.utl.DEBUG:0b

.utl.baseLoadV:{[x;v;allowReload];
  pkgInfo: .utl.requireVH.getPackageInfo[x;v;allowReload];
  / The convention used for packages will be to start by using an init file
  file: $[not 11h ~ type key pkgInfo[`file];pkgInfo[`file];` sv pkgInfo[`file],`init.q];
  if[not count key file; '"File '",(1 _ string file),"' not found"];
  oldFileLoading: .utl.FILELOADING;
  oldPkgLoading: .utl.PKGLOADING;
  / Let the name of the file being loaded and the "package" if available be accessed
  `.utl.PKGLOADING set .utl.requireVH.getPackageLoading[x;pkgInfo];
  `.utl.FILELOADING set .utl.realPath file;
  result:1b;
  / The require function prevents files from being loaded that have already been loaded
  / Files should NEVER be loaded recursively
  if[(allowReload or not file in .utl.LOADED) and not file in .utl.LOADING;
    .[`.utl.LOADING;();union;file];
    / NOTE:Consider supporting a debug flag to allow errors on require go uncaught
    result:@[{system "l ", x;1b};1 _ string file;(::)];  / The file is loaded and errors are caught
    .[`.utl.LOADING;();except;file];
    if[1b ~ result;.[`.utl.LOADED;();union;file]];
    ];
  `.utl.FILELOADING set oldFileLoading;
  `.utl.PKGLOADING set oldPkgLoading;
  $[1b ~ result;1b;'"Error loading '",(1 _ string file),"': ",result];
  }

.utl.loadV:.utl.baseLoadV[;;1b]
.utl.load:.utl.baseLoadV[;"";1b]
.utl.requireV:.utl.baseLoadV[;;0b]
.utl.require:.utl.baseLoadV[;"";0b]

/Get the real path of a filehandle cross platform (hopefully)
.utl.realPath:{
  rPath:{[absm;p] $[p like absm;p;` sv (hsym `$system "cd"), (`$1 _ string p)]};
  $["w" ~ (string .z.o) 0;
    rPath[":[A-z]:*";x];
    rPath[":/*";x]
    ]
  }

.utl.requireVH:((),`)!(),(::)
.utl.requireVH.getPackageInfo:{[loadArg;v;allowReload];
  $[-11h ~ type loadArg;
    `file`package!(loadArg;loadArg);
    / If a generic list is passed, we treat it as a symbol and characters, using the symbol as a package name
    / This is useful to allow requires that reference relative paths
    0h ~ type loadArg;
    `file`package!(` sv loadArg[0], `$"/" vs 1 _ loadArg;loadArg[0]);
    .utl.requireVH.findV[loadArg;v;allowReload]
    ]
  }

.utl.requireVH.getPackageLoading:{[loadArg;pkgInfo];
    / Package specified with a file handle using init.q extension
  $[(-11h ~ type loadArg) and pkgInfo[`file] like "*init.q";
    first ` vs pkgInfo[`file];
    / Package specified with a file handle and string component using directory path
    (0h ~ type loadArg) and 11h ~ type key pkgInfo `file;
    pkgInfo[`file];
    / All other .q files
    pkgInfo[`file] like "*.q";
    .utl.PKGLOADING;
    / The rest (new packages defined by loading argument)
    pkgInfo[`package]
    ]
  }

.utl.requireVH.packagesLoaded:{[package;v;allowReload];
  / If the the thing attempting to be loaded isn't a pure package, we're not going to try restricing it based on package id
  if[("" ~ v) and (package like "*-*") and package like "*[.0-9]";
    l: {$[1 < count x;("-" sv -1 _ x;-1#x);x]} "-" vs raze string package;
    v: raze "=",last l;
    package: first l];
  if[not package in key .utl.PKGSLOADED;:`];
  $[.utl.requireVH.makeFilter[v] file:.utl.PKGSLOADED package;
    file;
    allowReload;
    `;
    '"Error loading package '", package, "' with version '", v, "', there was a conflicting package version already loaded at ", 1 _ string file
    ]
  }

.utl.requireVH.allPackages:{raze {(` sv x,) each key x} each .utl.QPATH}
.utl.requireVH.findV:{[x;v;allowReload];
  / The paths passed to require should be the same across platforms
  packageName: first pathComponents: "/" vs x;
  if[not null path:.utl.requireVH.packagesLoaded[packageName;v;allowReload];
    :.utl.requireVH.foundDict[path;pathComponents]
    ];
  matchingPackage:.utl.requireVH.getMatchingPackage[allPackages:.utl.requireVH.allPackages[];packageName;v];
  exactPackage: first allPackages where allPackages like "*",packageName;
  / If a Version String has been provided (not "") we want to use the most recent matching
  / package and *then* fall back to an exact package name match.
  path: $[(v ~ "") and not null exactPackage;exactPackage;
    not null matchingPackage;matchingPackage;
    not null exactPackage;exactPackage;
    '"A matching package was not found for '",x,"' with version string '",v,"'.  Paths searched:\n\t", "\n\t" sv string .utl.QPATH];
  rval:.utl.requireVH.foundDict[path;pathComponents];
  / Keep track of loaded packages to prevent mismatching requires
  .utl.PKGSLOADED,:enlist["-" sv {$[(last[x] like "*[.0-9]") and 1 < count x;-1 _ x;x]} "-" vs packageName]!enlist[path];
  //.utl.PKGSLOADED,:enlist[first "-" vs packageName]!enlist[path];
  rval
  }

.utl.requireVH.getMatchingPackage:{[allPackages;packageName;v];
  matchingPackages: allPackages where ('[last;vs[`]] each allPackages) like "*",packageName,"*"; / Only consider the last part of the available paths as package names
  matchingPackages: matchingPackages where .utl.requireVH.makeFilter[v]  each matchingPackages;
  / Use the highest available package meeting the requirements
  first matchingPackages idesc (),.utl.requireVH.numVNStr .utl.requireVH.VNStrPath each matchingPackages
  }

/ Package numbers are only considered at the top level, special logic to support
/ sub-package elements (packages and files within a versioned package) is needed
.utl.requireVH.foundDict:{[path;pathComponents];
  subPackagePath: $[1 < count pathComponents;`$ 1 _ string ` sv `$@[1 _ pathComponents;0;":",];()];
  file: ` sv path,subPackagePath;
  package: 1 _ string ` sv (hsym last ` vs path),subPackagePath;
  `file`package!(file;package)
  }

/ Compare two Version Number Strings given an operator
/ It's much easier to do the partial application of the arguments for our purposes
/ if the second arg (the one on the right hand side) is passed in first
.utl.requireVH.cmpVNStr:{[op;vsn2;vsn1];
  if[not count vsn1;:0b];
  if[not count vsn2;:1b];
  op . .utl.requireVH.numVNStr (vsn1;vsn2)
  }

/ Create ordinal numbers from a list of Version Number Strings (Because a Version Number String could ostensibly have infinite depth, we need to work on them in groupings)
.utl.requireVH.numVNStr:{[vns0];
  if[not count vns0;:0];
  vns:"I"$"." vs' (),/:vns0;
  s: max count each vns;
  ns:{@[x#0;til count y;:;y]}[s] each vns;   / Fill out each list with 0's
  mvn:max each flip ns;
  exponents: reverse sums reverse ?[(1 _ mvn) > 0;1+`int$log[1 _ mvn] div log[10];1],0;
  sum each ns *\: `long$10 xexp' exponents / Get the total version numbers
  }

/ Get a Version Number String from the last element of a path
.utl.requireVH.VNStrPath:{`char$raze last "-" vs string last ` vs x}

/ Create a pair of operator and Version Number String
.utl.requireVH.parseVStr:{
  v: trim each "," vs x;
  pairs: {(0,0^1 + last x ss "[<>=]") _ x} each v; / Split the version specifiers into operator and number.
  .[pairs;(::;0);:;(("";(),"=";(),"<";(),">";">=";"<=";"<>")!(=;=;<;>;>=;<=;<>)) pairs[;0]] / Create the comparators
  }

/ Creates a Filter function based on a Version String
/ Individual comparison functions are created from each of the comma separated version string elements
.utl.requireVH.makeFilter:{[vstr];
  if[vstr ~ "";:{1b}];
  {all x @\: .utl.requireVH.VNStrPath y}[.utl.requireVH.cmpVNStr ./: .utl.requireVH.parseVStr vstr] / Partially apply the version string elements to get a list of comparators
  }
