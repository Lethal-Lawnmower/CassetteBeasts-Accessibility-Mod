# Changes Required to project.godot

Add the following to the `[autoload]` section of your decompiled `project.godot` file:

```ini
[autoload]

; ... existing autoloads ...
Accessibility="*res://global/Accessibility.gd"
```

The `*` prefix means it's a singleton that auto-loads when the game starts.

## Full Autoload Section Example

Your autoload section should look something like this after adding Accessibility:

```ini
[autoload]

Co="*res://addons/co_routine/Co.gd"
Strings="*res://addons/misc_utils/Strings.gd"
; ... many other autoloads ...
Accessibility="*res://global/Accessibility.gd"
```

**Note:** The order generally doesn't matter, but placing Accessibility at the end ensures all other singletons are loaded first.
