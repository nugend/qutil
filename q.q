{
 .u.QPATH: hsym each `$":" vs getenv x;
 bootstrap: b first where not 0 = (count key@) each b:` sv' .u.QPATH,'`bootstrap.q;
 system "l ", 1 _ string bootstrap;
 }[`QPATH]
 
