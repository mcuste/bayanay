# §7 — Descriptors, Properties, and `__init_subclass__`

## When to Use

- **`@property`**: One-off computed attributes, simple get/set on a single class
- **Descriptors**: Reusable validation/transformation logic shared across multiple classes
- **`__init_subclass__`**: Plugin registration, validation of subclass structure — replaces most metaclass use cases
- **Metaclasses**: Only when you need to control class *creation* (modifying `__new__`, MRO manipulation) — rare

## How It Works

**Descriptors** implement `__get__`, `__set__`, and/or `__set_name__`. They define reusable attribute behavior that works across many classes. `__set_name__` (3.6+) auto-captures the attribute name.

**`__init_subclass__`** (PEP 487) is called when a class is subclassed. It replaces most metaclass use cases for plugin registration and subclass validation.

## Code Snippet

```python
# Descriptor — reusable attribute validation
class Validated:
    def __init__(self, validator, *, default=None):
        self.validator = validator
        self.default = default

    def __set_name__(self, owner, name):
        self.name = name
        self.storage = f"_{name}"

    def __get__(self, obj, objtype=None):
        if obj is None:
            return self
        return getattr(obj, self.storage, self.default)

    def __set__(self, obj, value):
        self.validator(value)
        setattr(obj, self.storage, value)

class User:
    name = Validated(lambda v: None if v.strip() else (_ for _ in ()).throw(ValueError("blank")))
    age = Validated(lambda v: None if 0 < v < 200 else (_ for _ in ()).throw(ValueError("invalid")))

# __init_subclass__ — plugin registration
class Plugin:
    _registry: dict[str, type["Plugin"]] = {}

    def __init_subclass__(cls, *, name: str = "", **kwargs):
        super().__init_subclass__(**kwargs)
        key = name or cls.__name__.lower()
        Plugin._registry[key] = cls

class JSONPlugin(Plugin, name="json"):
    def process(self, data): ...

class CSVPlugin(Plugin, name="csv"):
    def process(self, data): ...

# Plugin._registry == {"json": JSONPlugin, "csv": CSVPlugin}
```

## Notes

- Descriptors are more powerful than `@property` but add complexity — use only when the behavior is reused
- `__init_subclass__` replaces 90% of metaclass use cases — prefer it for registration/validation
- Metaclasses are almost never needed in modern Python — reach for `__init_subclass__` or class decorators first
- `__set_name__` eliminates the need to pass the attribute name manually to descriptors
