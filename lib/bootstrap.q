.utl.LOADED:()
.utl.FILELOADING:`
.utl.PKGLOADING:""

.utl.requireV:{[x;v];
 pkgInfo: $[-11h ~ type x;
  `file`package!(x;x);
  / If you pass in a symbol and subsequent characters, we treat the symbol as if it's a package
  0h ~ type x;
  `file`package!(` sv x[0], `$"/" vs 1 _ x;x[0]);
  .utl.requireVH.findV[x;v]];
 / The convention used for packages will be to start by using an init file
 / Let the name of the file being loaded and the "package" if available be accessed
 file: $[-11h ~ type key pkgInfo[`file];pkgInfo[`file];` sv pkgInfo[`file],`init.q];
 if[not count key file; '"File '",(1 _ string file),"' not found"];
 oldFileLoading: .utl.FILELOADING;
 oldPkgLoading: .utl.PKGLOADING;
 `.utl.PKGLOADING set $[pkgInfo[`file] like "*.q";.utl.PKGLOADING;pkgInfo[`package]];
 `.utl.FILELOADING set file;
 result:1b;
 if[not file in .utl.LOADED;
  result:@[{system "l ", x;1b};1 _ string file;(::)];  / Catch errors here
  if[1b ~ result;.utl.LOADED,:file];
  ];
 `.utl.FILELOADING set oldFileLoading;
 `.utl.PKGLOADING set oldPkgLoading;
 $[1b ~ result;1b;'"Error loading '",(1 _ string file),"': ",result];
 }
.utl.require:.utl.requireV[;""]

.utl.requireVH:((),`)!(),(::)
.utl.requireVH.findV:{[x;v];
 / I'd like the require paths to be the same across platforms
 packageName: first pathComponents: "/" vs x;
 allPackages: raze {(` sv x,) each key x} each .utl.QPATH;
 matchingPackages: allPackages where allPackages like "*",packageName,"*";
 matchingPackages: matchingPackages where .utl.requireVH.makeFilter[v]  each matchingPackages;
 / This should be the highest available package meeting the requirements
 matchingPackage: first matchingPackages idesc .utl.requireVH.numVNStr .utl.requireVH.VNStrPath each matchingPackages;
 exactPackage: first allPackages where allPackages like "*",packageName;
 path: $[(v ~ "") and not null exactPackage;exactPackage;
  not null matchingPackage;matchingPackage;
  not null exactPackage;exactPackage;
  '"A matching package was not found for '",x,"' with version string '",v,"'.  Paths searched:\n\t", "\n\t" sv string .utl.QPATH];
 packageSubName: $[1 < count pathComponents;`$ 1 _ string ` sv `$@[1 _ pathComponents;0;":",];()];
 file: ` sv path,packageSubName;
 package: 1 _ string ` sv (hsym last ` vs path),packageSubName;
 `file`package!(file;package)
 }

/ It's much easier to do the partial application of the arguments if the second arg
/ (the one on the right hand side) is passed in first
.utl.requireVH.cmpVNStr:{[op;vs2;vs1];
 if[not count vs1;:0b];
 if[not count vs2;:1b];
 op . .utl.requireVH.numVNStr (vs1;vs2)
 }

.utl.requireVH.numVNStr:{[vals];
 if[not count vals;:0];
 vals:"I"$"." vs' (),/:vals;
 s: max count each vals;
 ns:{@[x#0;til count y;:;y]}[s] each vals;   / Fill out each list with 0's
 sum each ns *\: reverse `int$10 xexp' til s / Get the total version numbers
 }

.utl.requireVH.VNStrPath:{"." sv string 1 _ ` vs last ` vs x}

.utl.requireVH.parseVStr:{
 v: trim each "," vs x;
 pairs: {(0,0^1 + last x ss "[<>=]") _ x} each v; / Split the version specifiers into operator and number.
 .[pairs;(::;0);:;(("";(),"=";(),"<";(),">";">=";"<=";"<>")!(=;=;<;>;>=;<=;<>)) pairs[;0]] / Create the comparators
 }

.utl.requireVH.makeFilter:{[vstr];
 if[vstr ~ "";:{1b}];
 {all x @\: .utl.requireVH.VNStrPath y}[.utl.requireVH.cmpVNStr ./: .utl.requireVH.parseVStr vstr]
 }
