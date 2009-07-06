.tst.desc["A Config Parser"]{
  should["support multiple sections"]{};
  should["raise an error if there is not one section"]{};
  should["recognize colon as a name-value pair separator"]{};
  should["recognize equals as a name-value pair separator"]{};
  should["raise an error if there is an empty key"]{};
  should["support multivalued pairs by creating a list of values if multi-valued is enabled"]{};
  should["handle RFC 822 style LONG HEADER FIELD continuations"]{};
  should["ignore lines beginning with sharp"]{};
  should["ignore lines beginning with semi-colon"]{};
  should["fill values from a DEFAULT section if available"]{};
  should["handle name substitution in values"]{};
  };
