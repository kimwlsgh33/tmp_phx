# CSS and Styling Guide

This document outlines our CSS and styling practices for the Phoenix application.

## CSS Architecture

### File Structure
```
assets/
├── css/
│   ├── app.css
│   ├── components/
│   ├── layouts/
│   └── utilities/
```

### Naming Conventions
We follow BEM (Block Element Modifier) methodology:
```css
.block {}
.block__element {}
.block--modifier {}
```

## Components

### Base Components
- Buttons
- Forms
- Typography
- Cards

### Layout Components
- Grid system
- Containers
- Navigation

## Utilities

### Spacing
```css
.m-1 { margin: 0.25rem; }
.p-1 { padding: 0.25rem; }
```

### Colors
```css
:root {
  --primary: #4a90e2;
  --secondary: #50e3c2;
  --error: #e74c3c;
}
```

## Best Practices

### Performance
- Minimize specificity
- Use CSS custom properties
- Optimize critical CSS

### Responsive Design
```css
@media (min-width: 768px) {
  /* Tablet styles */
}

@media (min-width: 1024px) {
  /* Desktop styles */
}
```

### Accessibility
- Color contrast
- Focus states
- Screen reader support
