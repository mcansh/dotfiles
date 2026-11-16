# Component Design — Implementation Patterns

Working code for the patterns described in SKILL.md.

## Compound components with context

Share implicit state through React context, not props — the root provides, the parts consume:

```jsx
const DialogContext = createContext(null);

function Dialog({ children }) {
  const [open, setOpen] = useState(false);
  return (
    <DialogContext.Provider value={{ open, setOpen }}>
      {children}
    </DialogContext.Provider>
  );
}

function DialogTrigger({ onClick, ...props }) {
  const { setOpen } = useContext(DialogContext);
  return (
    <button
      type="button" // inside a <form>, the default "submit" would submit it
      {...props}
      onClick={(event) => {
        onClick?.(event); // compose the consumer's handler, don't let a spread replace ours
        if (!event.defaultPrevented) setOpen(true);
      }}
    />
  );
}
```

## Controlled + uncontrolled in one component

Internal state by default, external state when the consumer provides `value`:

```jsx
function Input({
  value: controlledValue,
  defaultValue,
  onChange,
  ...props
}) {
  const [internalValue, setInternalValue] = useState(defaultValue ?? "");

  const isControlled = controlledValue !== undefined;
  const value = isControlled ? controlledValue : internalValue;

  function handleChange(e) {
    if (!isControlled) {
      setInternalValue(e.target.value);
    }
    onChange?.(e);
  }

  return <input value={value} onChange={handleChange} {...props} />;
}

// Uncontrolled
<Input defaultValue="hello" />

// Controlled — onChange receives the event, not the value
<Input value={value} onChange={(e) => setValue(e.target.value)} />
```

## `asChild` with Radix Slot

```jsx
import { Slot } from "@radix-ui/react-slot";

function Button({ asChild, ...props }) {
  const Comp = asChild ? Slot : "button";
  // a native button defaults to submit inside a form; the child keeps its own semantics
  return <Comp {...(!asChild && { type: "button" })} {...props} />;
}
```

## Forwarding refs

Always pass refs through on components that wrap DOM elements. In React 19+, `ref` is a plain prop:

```tsx
function Button({ ref, children, ...props }: React.ComponentProps<"button">) {
  return (
    <button ref={ref} type="button" {...props}>
      {children}
    </button>
  );
}
```

`forwardRef` is only for React ≤18:

```tsx
const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ children, ...props }, ref) => {
    return (
      <button ref={ref} type="button" {...props}>
        {children}
      </button>
    );
  }
);
```

## Spreading remaining props

Allow arbitrary HTML attributes to pass through:

```jsx
function Button({ variant, size, className, ...props }) {
  return (
    <button
      type="button"
      className={cn(buttonVariants({ variant, size }), className)}
      {...props}
    />
  );
}

// Now these work:
<Button type="submit" data-testid="submit">
  Submit
</Button>
```

## Sensible defaults

Defaults should cover 80% of usages:

```jsx
function Button({
  variant = "primary",
  size = "md",
  type = "button", // Not "submit" - safer default
  ...props
}) {
  // ...
}
```

## Slot pattern for optional sections

```jsx
function Card({ children, header, footer }) {
  return (
    <div className="card">
      {header && <div className="card-header">{header}</div>}
      <div className="card-content">{children}</div>
      {footer && <div className="card-footer">{footer}</div>}
    </div>
  );
}

// Usage
<Card
  header={<h2>Title</h2>}
  footer={<Button>Save</Button>}
>
  Main content
</Card>
```

## Error boundaries

Wrap complex components in error boundaries so one broken widget doesn't take down the page:

```jsx
function ComponentWithErrorBoundary({ children }) {
  return (
    <ErrorBoundary fallback={<ErrorFallback />}>
      {children}
    </ErrorBoundary>
  );
}
```

## File structure and exports

```
components/
├── button/
│   ├── button.tsx        # Main component
│   ├── button.test.tsx   # Tests
│   └── index.ts          # Public exports
├── card/
│   ├── card.tsx
│   ├── card-header.tsx
│   ├── card-content.tsx
│   └── index.ts
```

```tsx
// components/card/index.ts
export { Card } from "./card";
export { CardHeader } from "./card-header";
export { CardContent } from "./card-content";

// Or as compound component
export { Card, CardHeader, CardContent } from "./card";
```
