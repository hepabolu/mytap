---
layout: default
title: Tests
permalink: /tests/
---

# {{ page.title }}

Need to make sure that your schema is designed just the way you think it
should be? Use these test functions and rest easy.

A note on comparisons: MyTAP uses a simple equivalence test (`=`) to compare
identifier names.

This page lists all available tests in the MyTAP project.

# Introduction

The tests are functions that test an expected aspect of the data model. All functions have an optional description. That is, if you provide an empty string as description, the default description will be shown.

If you want to test an aspect in the current schema, use the `database()` function to specify the current schema name.

# The Schema Things

## Tables

### `has_table( schema, table, description )`

```sql
SELECT has_table(database(), 'sometable', 'I got sometable');
```

This function tests whether a table exists in a schema. The first
argument is a schema name, the second is a table name, and the third is the
test description. 

`__hasnt_table( schema, table, description )` checks if the table does NOT exist.

### `table_engine_is( schema, table, engine, description )`

`table_engine_is( schema, table, engine, description )` checks if the table has the provided engine.

### `table_collation_is( schema, table, collation, description )`

`table_collation_is( schema, table, collation, description )` checks if the table has the provided collation.

### `table_character_set_is( schema, table, charset, description )`

`table_character_set_is( schema, table, charset, description )` checks if the table has the provided character set.

### `tables_are( schema, want, description )`

This function tests for the existence of named tables. Identifies both missing as well as extra tables.
`want` contains a comma separated list of tables that should be available.

### `table_sha1_is ( schema, table, sha1, description )`

Check for schema changes by calculating the SHA-1 from the table definition and it's constituent schema objects.

This test has 3 versions based on the MySQL version (5.5 (default), 5.6 and 5.7).

## Columns

### `has_column( schema, table, column, description )`

This function tests whether the column exists in the given table of the schema.

`hasnt_column( schema, table, column, description )` checks if the column does NOT exist

### `col_is_null( schema, table, column, description )`

This function tests if the column has the attribute 'allow null'.

`col_not_null( schema, table, column, description )` checks if the column does NOT have the attribute 'allow null'.

### `col_has_primary_key( schema, table, column, description )`

This function tests if the column is part of a primary key.

`col_hasnt_primary_key( schema, table, column, description )` checks if the column is NOT part of a primary key.

### `col_has_index_key( schema, table, column, description )`

This function tests if the column is part of a key, not a primary key.

`col_hasnt_index_key( schema, table, column, description )` checks if this column is NOT part of a key.

`col_has_unique_index`( schema, table, column, description )` checks if this column has a unique key other than the primary key.

`col_hasnt_unique_index`( schema, table, column, description )` checks if this column doesn't have a unique key other than the primary key.

### `col_has_named_index( schema, table, column, keyname, description )`

This function tests if the column is part of a key with a specific name.

`col_has_named_index( schema, table, column, keyname, description )` checks if the column is NOT part of a key with a specific name.

### `col_has_pos_in_named_index( schema, table, column, keyname, position, description )`

This function tests if the column has the given position in a composite index of the given name. A composite index is an index on multiple columns.

`col_hasnt_pos_in_named_index( schema, table, column, keyname, position, description )` checks if the column does NOT have the given position in the given index.

### `col_has_type( schema, table, column, type, description )`

This function tests if the column has the given column type, so `VARCHAR(64)` rather than `VARCHAR`.

__2018-07-21 This test is removed in version 1.0__:
`col_hasnt_type( schema, table, column, type, description )` checks if the column does NOT have the given data type.

### `col_data_type_is( schema, table, column, datatype, description )`

`col_data_type_is( schema, table, column, datatype, description )` checks if the column has the given data type, so `VARCHAR` if the column is of type `VARCHAR(64)`.

### `col_column_type_is( schema, table, column, columntype, description)` 

`col_column_type_is( schema, table, column, columntype, description)` check if the column has the given column type, so `VARCHAR(64)` rather than `VARCHAR`. This test is equivalent to `col_has_type`.

### `col_has_default( schema, table, column, description )`

This function tests if the column has a default value. Note, this function does NOT tests the actual default value, just that the attribute of a default value is set.

`col_hasnt_default( schema, table, column, description )` checks if the column does NOT have the 'default' attribute set.

### `col_default_is( schema, table, column, default, description )`

This function tests if the column has the given default value.
__Note__: MySQL 5.5x does not distinguish between 'no default' and
'null as default' and 'empty string as default'.

### `col_extra_is( schema, table, column, extra, description )`

This function tests if the column has the given extra attributes. Examples of 'extra' are `on update current timestamp`.

### `col_charset_is( schema, table, column, charset, description )`

This function tests if the column has the given character set.

`col_character_set_is( schema, table, column, charset, description )` is a synonym for `col_charset_is`.


### `col_collation_set_is( schema, table, column, collation, description )`

This function tests for the given collation.

### `columns_are( schema, table, want, description )`

This function tests for the existence of named columns within a table. Identifies both missing as well as extra columns.
`want` contains a comma separated list of columns that should be available.


## Routines

### `has_routine( schema, name, type, description )`

This function checks if a routine of type `type` with name `name` exists in the schema.

`hasnt_routine( schema, name, type, description )`

This function checks if a routine of type `type` with name `name` does NOT exist in the schema.

### `has_function( schema, function, description )`

This function tests if the function with the given name exists in the schema.
This function calls `has_routine` with type 'Function'.

`hasnt_function( schema, function, description )` checks if the function with the given name does NOT exist in the schema.
This function calls `hasnt_routine` with type 'Function'.

### `has_procedure( schema, procedure, description )`

This function tests if the procedure with the given name exists in the schema.
This function calls `has_routine` with type 'Procedure'.

`hasnt_procedure( schema, procedure, description )` checks if the procedure with the given name does NOT exist in the schema.
This function calls `hasnt_routine` with type 'Procedure'.

### `function_data_type_is( schema, function, data_type, description )`

This function tests if the function with the given name returns the given data type.

### `function_is_deterministic( schema, function, on_or_off, description )`

This function tests if the function with the given name has is_deterministic set to the value of on_or_off.

### `procedure_is_deterministic( schema, procedure, on_or_off, description )`

This function tests if the procedure with the given name has is_deterministic set to the value of on_or_off.

### `function_security_type_is( schema, function, security_type, description )`

This function tests if the function with the given name has the given security_type.

### `procedure_security_type_is( schema, procedure, security_type, description )`

This function tests if the procedure with the given name has the given security_type.

### `function_sql_data_access_is( schema, function, sql_data_access, description )`

This function tests if the function with the given name has the given SQL data access.

### `procedure_sql_data_access_is( schema, procedure, sql_data_access, description )`

This function tests if the procedure with the given name has the given SQL data access.

### `routines_are( schema, type, want, description )`

Test for the existence of named routines of given type. Identifies both missing as well as extra routines.
`want` contains a comma separated list of routine names of the given type.

### `routine_has_sql_mode( schema, name, type, sqlmode, description )`

Check that a particular SQL mode will apply to a named routine of the given type within the given schema.

### `routine_sha1_is( schema, name, type, sha1, description)`

Get the SHA1 value of a routine body to compare against a previous value.

## Views

### `has_view ( schema, view, description )`

This function tests if the view with the given name exists in the schema.

`hasnt_view ( schema, view, description )` checks if the view with the given name does NOT exist in the schema.

### `has_security_invoker ( schema, view, description )`

This function tests if the view has the attribute `security INVOKER`.

`has_security_definer ( schema, view, description )` checks if the view has the attribute `security DEFINER`.

### `view_security_type_is( schema, view, security, description )`

This function checks if the security type is of the given type. This is a synonym for `has_security_invoker` and `has_security_definer`.

### `view_check_option_is( schema, view, option, description )`

This function checks the check option of the view.

### `view_is_updatable( schema, view, updatable, description )`

This function checks if a view is updatable. Provide 'YES' or 'NO' as values for `updatable`.

### `view_definer_is( schema, view, definer, description )`

This function checks if the view has the given definer.

### `views_are( schema, want, description )`

This function tests for the existence of named views. Identifies both missing as well as extra views.
`want` contains a comma separated list of views that should be available.


## Triggers

### `has_trigger ( schema, table, trigger, description )`

This function checks if a trigger with the given name exists for the given table exists in the schema.

`hasnt_trigger ( schema, table, trigger, description )` checks if a trigger with the given name exists for the given table does NOT exist in the schema.

### `trigger_event_is( schema, table, trigger, event, description )`

This function checks if a trigger with the given name for the given table is fired on a given event (INSERT, UPDATE, DELETE).

### `trigger_timing_is( schema, table, trigger, timing, description )`

This function checks if a trigger with the given name for the given table is fired at the given time (BEFORE, AFTER).

### `trigger_order( schema, table, trigger, order, description )`

This function tests the ordinal position of the trigger's action within the list of triggers on the same table with the same event and timing values.
__NOTE__: Before MySQL 5.7.2, this value is always 0 because it is not possible for a table to have more than one trigger with the same event and timing values.

### `trigger_is( schema, table, trigger, body, description )`

This function checks if the content of the trigger action is equal to `body`. __NOTE__: this might be difficult to test is the statement list is long.

### `triggers_are( schema, want, description )`

This functions tests for the existence of named triggers. Identifies both missing as well as extra triggers.
`want` contains a comma separated list of triggers that should be available.

## Schemata

### `has_schema( schema, description )`

This function checks if a given schema exists.

`hasnt_schema( schema, description )`

This function checks if a given schema does NOT exist.

### `schema_collation_is( schema, collation, description )`

`schema_collation_is( schema, collation, description )` checks if the schema has the provided default collation.

### `schema_character_set_is( schema, charset, description )`

`schema_character_set_is( schema, charset, description )` checks if the schema has the provided default character set.

### `schemas_are( schema, want, description )`

This function tests for the existence of named schemas. Identifies both missing as well as extra schemas.
`want` contains a comma separated list of schemas that should be available.

## Database server

### `has_charset( charset, description )`
### `has_character_set( charset, description )`

This function checks if the given character set is available. `has_character_set` is a synonym for `has_charset`.

`hasnt_charset( charset, description )`
`hasnt_character_set( charset, description )`

This function checks if the given character set is NOT available. `hasnt_character_set` is a synonym for `hasnt_charset`.

### `has_collation( collation, description )`

This function checks if the given collation is available.

`hasnt_collation( collation, description )`

This function checks if the given collation is NOT available.

### `has_engine( engine, description )`

This function checks if the given storage engine is supported.

### `engine_is_default( engine, description )`

This function checks if the given storage engine is set as default.

### `global_is( var, want, description )`

This function checks the state of a global variable.

## Events

### `scheduler_is( want, description )`

This function checks if the event schedule has the given status.

### `has_event( schema, event, description )`

This function checks if the given event exists in the schema.

`hasnt_event( schema, event, description )`

This function checks if the given event does NOT exist in the schema.

### `event_type_is( schema, event, type, description )`

This function checks if the event has the given type ('ONE TIME' or 'RECURRING').

### `event_interval_value_is( schema, event, value, description )`

This function checks the interval value of a recurring event.

### `event_interval_field_is( schema, event, field, description )`

This function checks if the interval field has the given value, e.g. 'HOUR'.

### `event_status_is( schema, event, status, description )`

This function checks if the event has the given status.

### `events_are( schema, want, description )`

This functions tests for the existence of named events. Identifies both missing as well as extra events.
`want` contains a comma separated list of events that should be available.

## Constraints

### `has_constraint( schema, table, constraint, description )`

This function checks if the table has the given constraint.

`hasnt_constraint( schema, table, constraint, description )`

This function checks if the table does not have the given constraint.

### `has_pk( schema, table, description )`

This function checks if the table has a primary key.

`hasnt_pk( schema, table, description )`

This function checks if the table does not have a primary key.

### `has_fk( schema, table, description )`

This function checks if the table has a foreign key.

`hasnt_fk( schema, table, description )`

This function checks if the table does not have a foreign key.

### `col_is_unique( schema, table, want, description )`

This function checks if the table has a unique index on the given columns. `want` contains a comma separated list of columns.

### `col_is_pk( schema, table, want, description )`

This function checks if the table has a primary key on the given columns. `want` contains a comma separated list of columns.

### `has_unique( schema, table, description )`

This function checks if the table has a unique (UNIQUE or PRIMARY) index.

### `constraint_type_is( schema, table, constraint, type, description )`

This function checks if the constraint has the given type (FK, PK, UNIQUE).

### `fk_on_delete( schema, table, constraint, rule, description )`

This function checks if the constraint has an 'ON DELETE' rule.

### `fk_on_update( schema, table, constraint, rule, description )`

This function checks if the constraint has an 'ON UPDATE' rule.

### `fk_ok(schema, table, columns, rschema, rtable, rcolumns, description )`

This function checks that a foreighn key points to the correct table and indexed columns key.
`rschema`, `rtable`, `rcolumns` are the referenced schema, table and columns resp. 
`columns` and `ucolumns` are comma separated lists of columns.

### `constraints_are( schema, table,  want, description )`

This functions tests for the existence of named constraints. Identifies both missing as well as extra constraints.
`want` contains a comma separated list of constraints that should be available.

## Indexes

### `index_is( schema, table, index, want, description )`

This function checks if the given index contains the given column list. `want` contains a comma separated list of columns.

### `is_indexed( schema, table, want, description )`

This function checks if there is an index covering the columns supplied (in the order provided).

### `has_index( schema, table, index, description )`

This function checks if the table has an index with the given name.

`hasnt_index( schema, table, index, description )`

This function checks if the table does not have an index with the given name.

### `index_is_type( schema, table, index, type, description )`

This function checks if the index is of given type (BTREE, FULLTEXT, SPATIAL).

### `indexes_are( schema, table,  want, description )`

This functions tests for the existence of named indexes. Identifies both missing as well as extra indexes.
`want` contains a comma separated list of indexes that should be available.


## Partitions

### `has_partitioning(description )`

This function checks if partitioning is available.

### `has_partition( schema, table, partition, description )`

This function checks if the table has the given partition.

`hasnt_partition( schema, table, partition, description )`

This function checks if the table does not have the given partition.

### `has_subpartition( schema, table, subpartition, description )`

This function checks if the table has the given subpartition.

`hasnt_subpartition( schema, table, subpartition, description )`
This function checks if the table does not have the given subpartition.

### `partition_expression_is( schema, table, partition, expression, description )`

This function checks if the partition has the given expression.

### `subpartition_expression_is( schema, table, subpartition, expression, description )`

This function checks if the subpartition has the given expression.

### `partition_method_is( schema, table, partition, method, description )`

This function checks if the partition has the given method, e.g. 'RANGE'.

### `subpartition_method_is( schema, table, subpartition, method, description )`

This function checks if the subpartition has the given method, e.g. 'HASH'.

### `partition_count_is( schema, table, count, description )`

This function checks the number of partitions defined for the table.

### `partitions_are( schema, table, want, description )`

This functions tests for the existence of named partitions. Identifies both missing as well as extra partitions.
`want` contains a comma separated list of partitions that should be available.


## Users

### `has_user(host, user, description )`

This function checks if 'user'@'host' exists.

### `hasnt_user(host, user, description )`

This function checks if 'user'@'host' does not exist.


### `has_user_at_host("'user'@'host'", description )`

As has_user but takes a single argument for the user and host. The user and host must be separately quoted and can
use any of the legal quoting styles, i.e. single, double or backtick. In addition, if the user and host names are
valid unquoted identifiers (do not contain special characters) they can be left unquoted.

### `hasnt_user_at_host("'user'@'host'", description )`

This function checks if 'user'@'host' does not exist.


### `user_ok(host, user, description )`

This function checks if 'user'@'host' is not disabled.

### `user_not_ok(host, user, description )`

This function checks if 'user'@'host' is disabled.

### `user_has_lifetime(host, user, description )`

__NOTE__: This is a feature of MySQL 5.7. In older versions these functions will always return 'not ok'.
This function checks if the password should expire.

`user_hasnt_lifetime(host, user, description )`

This function checks if the password should not expire.



## Privileges

A series of tests for privileges granted on user and role accounts.

Please note that the tests are specific to the named user or role that is being tested (grantee) and do not include the
effect of any proxied privileges that may be granted or, in the case of a user, any privileges that are
granted to a role to which they have been assigned.

Privileges can be granted within MySQL at a number of levels and have a cascading effect on to lower-levels where the
same privilege applies. The SELECT privilege granted at the global level implies the same privilege at a schema, table and column levels.
Similarly, the EXECUTE privilege granted on routines at a global level, implies the same at the schema and routine levels. On the
other hand, the FILE privilege is only granted at a global level and is invalid at lower levels.

MyTAP privilege tests allow for the possibilty that the user may wish to test that a privilege is active at a specific
level having been granted at a higher level just as much as for privileges granted explicitly at the level being tested (the default).
To include the effect of these cascaded privileges you should set a user-defined variable @rollup to TRUE in your test script.

e.g.

```
SET @rollup=1;

SELECT tap.table_privileges_are('db','tableA','myuser@localhost', SELECT,UPDATE,INSERT,DELETE','');
````

Will take account privileges granted with any of these the statements

```
GRANT SELECT,UPDATE,INSERT,DELETE ON *.* TO 'myuser'@'localhost';
GRANT SELECT,UPDATE,INSERT,DELETE ON `db`.* TO 'myuser'@'localhost';
GRANT SELECT,UPDATE,INSERT,DELETE ON `db`.`tableA` TO 'myuser'@'localhost';
```

whereas,

```
SET @rollup=0;

SELECT tap.table_privileges_are('db','tableA','myuser@localhost', SELECT,UPDATE,INSERT,DELETE','');
```

Will test for privileges granted explicitly at the table level with

```
GRANT SELECT,UPDATE,INSERT,DELETE ON `db`.`tableA` TO 'myuser'@'localhost';
```


### Grantee

The grantee parameter can be in any of the formats permitted by MySQL when the user or role is created. The
following are, therefore, considered equivalent:

1. myuser@localhost
2. 'myuser'@'localhost'
3. "myuser"@"localhost"
4. \`myuser\`@\`localhost\`

If the host part is ommitted then the wildcard '%' is assumed.


### `has_privilege(grantee, privilege_type, description)`

Test whether `privilege_type` has been granted to the user or role at any level.


### `hasnt_privilege(grantee, privilege_type, description)`

Check that `privilege_type` has not been granted to the user or role at any level.


### `has_global_privilege(grantee, privilege_type, description)`

Test whether the specified privilege has been granted to the user or role at the global level. Rollup is not applicable
for global-level tests.


### `hasnt_global_privilege(grantee, privilege_type, description)`

Test whether the specified privilege has not been granted to the user or role at the global level. Rollup is not applicable
for global-level tests.


### `has_schema_privilege(schema, grantee, privilege_type, description)`

Test whether the specified schema-level privilege has been granted to the user or role. With 'rollup'
enabled this will test whether the privilege has been granted at either the global or the schema levels.


### `hasnt_schema_privilege(schema, grantee, privilege_type, description)`

Test whether the specified schema-level privilege has not been granted to the user or role. With 'rollup'
enabled this will check that the privilege has not been granted at either the global or schema levels.


### `has_table_privilege(schema, table, grantee, privilege_type, description)`

Test whether the specified table-level privilege has been granted to the user or role. With 'rollup'
enabled this will test whether the privilege has been granted at either at the global, schema or table levels.


### `hasnt_table_privilege(schema, table, grantee, privilege_type, description)`

Test whether the specified table-level privilege has not been granted to the user or role. With 'rollup'
enabled this will check that the privilege has not been granted at the global, schema or table levels.


### `has_column_privilege(schema, table, column, grantee, privilege_type, description)`

Test whether the specified column-level privilege has been granted to the user or role. With 'rollup'
enabled this will test whether the privilege has been granted at the global, schema, table or column levels.

### `hasnt_column_privilege(schema, table, column, grantee, privilege_type, description)`

Test whether the specified table-level privilege has not been granted to the user or role. With 'rollup'
enabled this will check that the privilege has not been granted at the global, schema, table or column levels.


### `global_privileges_are(grantee, privilege_list, description)`

Test the privileges granted to the user or role at the global-level. The list of privilege must be comma-separated
and you should ensure there are no extra spaces either before or after each privilege type.  Where either missing and
extra privileges are defined these will be listed in a diagnostic message in the function return. Rollup is not
applicable for global-level tests.

### `schema_privileges_are(schema, grantee, privilege_types, description)`

Test the privileges granted to the user or role at the schema-level. The list of privilege must be comma-separated
and you should ensure there are no extra spaces either before or after each privilege type.  Where either missing and
extra privileges are defined these will be listed in a diagnostic message in the function return. With rollup enabled
the function will check for privileges granted at either the global and schema levels.


### `table_privileges_are(schema, table, grantee, privilege_types, description)`

Test the privileges granted to the user or role at the table-level. The list of privilege must be comma-separated
and you should ensure there are no extra spaces either before or after each privilege type.  Where either missing and
extra privileges are defined these will be listed in a diagnostic message in the function return. With rollup enabled
the function will check for privileges granted at the global, schema or table levels.


### `column_privileges_are(schema, table, column, grantee, privilege_types, description)`

Test the privileges granted to the user or role at the column-level. The list of privilege must be comma-separated
and you should ensure there are no extra spaces either before or after each privilege type.  Where either missing and
extra privileges are defined these will be listed in a diagnostic message in the function return. With rollup enabled
the function will check for privileges granted at the global, schema, table or column levels.


### `routine_privileges_are(schema, routine_type, routine_name, grantee, privilege_types, description)`

Test the privileges granted to the user or role at the routine-level. The list of privilege must be comma-separated
and you should ensure there are no extra spaces either before or after each privilege type.  Where either missing and
extra privileges are defined these will be listed in a diagnostic message in the function return. With rollup enabled
the function will check for privileges granted at the global, schema or routine levels.


### `single_schema_privileges(schema, grantee, description)`

Test that all privileges granted to the user or role are confined to a single schema.


### `single_table_privileges(schema, table, grantee, description)`

Test that all privileges granted to the user or role are confined to a single table or view.
