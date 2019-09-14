enve-table(3) -- table manipulation functions
==================================

## 提要 SYNOPSIS

`. "$ENVE_HOME/enve/envelib"`


## Constance

```
tab='\t'
feed='\f'
vtab='\v'
newl='\n'
```

## Function

`table_tail` <match> [<type>]

`table_subset` <match> [<type>]

`table_exclude` <match> [<type>]

`table_substi` <var_table>


接下來的`as_*`系列都是管道函數，接收TABLE作為input，輸出特定格式的內容。

`as_postfix` <postfix>

`as_rootkey`

`as_value`

`as_uniquekey`

`as_concat`

`out_item` <type> <key> <value>
`out_var` <key> <value>
`out_var_fast` <key> <value>
`out_var_just` <key> <value>

`out_alias` <key> <value>
`out_list` <key> <value>
`out_join` <key> <value>
`out_source` <key> <value>
`out_code` <key> <value>
`out_secret` <key> <value>

`parse_config_recursive` roles=? <file>

`enve_fire` ENVE_PROFILE=? ENVE_ROLES=? ENVE_CONFIG=? <RCFILE_PATH>
