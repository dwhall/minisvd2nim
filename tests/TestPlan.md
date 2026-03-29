# Test Plan

foreach [Direct peripheral, Indirect peripheral, Indirect register]:

  register:
  - "declareRegister SHOULD provide a symbol for the register"
  - "read SHOULD compile"
  - "read SHOULD work"
  - "raw read SHOULD yield a distinct type"
  - "read from read-only SHOULD work"
  - "read from write-only SHOULD NOT compile"
  - "write to the register SHOULD work"
  - "write the register's distinct type SHOULD compile"
  - "write the register's distinct type SHOULD work"
  - "write another register's distinct type SHOULD NOT compile"
  - "read then write the register's distinct type SHOULD work"
  - "write unsupported type to the register SHOULD NOT compile"
  - "write to the read-only register SHOULD NOT compile"
  - "write to the write-only register SHOULD work"

  field:
  - "declareField SHOULD provide a symbol for the field"
  - "read SHOULD compile"
  - "read SHOULD work"
  - "write (field=) SHOULD overwrite the whole register"
  - "rmw the field SHOULD only change the bits of the field"
  - "rmw two fields SHOULD change the bits of both fields an no others"
  - "rmw with one read-only field SHOULD NOT compile"
  - "read from read-only SHOULD work"
  - "read from write-only SHOULD NOT compile"
  - "write to read-only SHOULD NOT compile"
  - "write to write-only SHOULD work"
