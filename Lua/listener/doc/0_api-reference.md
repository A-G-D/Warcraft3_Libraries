# API Reference

Listener v1.0.0

```Lua
Listener ---@type table
```

The Listener 'class'

```Lua
function Listener:register(func [, data [, max_recursion_depth]])
```

Registers a listener function or a callable table to respond to an event.

| Parameters: |||
|---|---|---|
| **Name** | **Type** | **Description** |
| *func* | function \| table | The listener function or table |
| *data* | any | The data passed to *func* upon execution |
| *max_recursion_depth* | integer | The maximum allowed recursion for *func* in a single execution |
||||

| Return value: |||
|---|---|---|
| **#** | **Type** | **Description** |
| *1* | table | self (To allow chained commands) |
||||

```Lua
function Listener:deregister(func)
```

Deregisters a listener function/table.

| Parameters: |||
|---|---|---|
| **Name** | **Type** | **Description** |
| *func* | function \| table | The listener function or table |
||||

| Return value: |||
|---|---|---|
| **#** | **Type** | **Description** |
| *1* | table | self (To allow chained commands) |
||||

```Lua
function Listener:clear()
```

Deregisters all existing listeners.

| Parameters: |||
|---|---|---|
| **Name** | **Type** | **Description** |
| *N/A* | *N/A* | *N/A* |
||||

| Return value: |||
|---|---|---|
| **#** | **Type** | **Description** |
| *1* | table | self (To allow chained commands) |
||||

```Lua
function Listner:__call([reverse [, ...]])
function Listener:execute([reverse [, ...]])
```

Executes an all registered event listeners.

| Parameters: |||
|---|---|---|
| **Name** | **Type** | **Description** |
| *reverse* | boolean | If true, the order of execution of registered listeners is reversed |
| *...* | any | Data passed to all the executed listeners |
||||

| Return value: |||
|---|---|---|
| **#** | **Type** | **Description** |
| *1* | table | self (To allow chained commands) |
||||
