Read and analyze the latest UICrit export — a UI snapshot from the iOS simulator with screenshots, view hierarchy, and visual properties. Use when the user says "check uicrit", "check annotation", "read uicrit", or references the UICrit tool.

# UICrit Export Reader

## What is UICrit?

UICrit is a debug overlay for UIKit apps. The developer selects an area of the screen in the simulator, optionally adds a note, and exports a structured snapshot. The export includes:

- **Screenshots**: `fullscreen.jpg` (entire screen) and `area.jpg` (cropped to selection), or individual `{id}.jpg` files for single-element exports
- **Structured data**: `export.json` with the view hierarchy, property names, visual properties, and owning view controllers for all views in the selected area
- **Human-readable summary**: `export.md`

The purpose is to give you (Claude) precise context about a piece of UI so you can make targeted code changes without guessing.

## How to read the export

1. Read `/tmp/UICrit/latest/export.json` first — this is the structured data
2. **In a single parallel batch**, read all of the following at once:
   - `/tmp/UICrit/latest/area.jpg` (if area export) or the screenshot files listed in `screenshot_filename` fields (if single-element export)
   - `/tmp/UICrit/latest/fullscreen.jpg` (full screen context, area exports only)
   - The source files identified in `export.json` — use `cell_class_name` or `view_controller_name` from the elements to determine which `.swift` files to read. This ensures you can edit immediately without an extra round trip.
3. If the user included a note, it will be in the `note` field of `export.json` — this is their request or observation

## Export schema (v1.2.0)

### Area export

```json
{
  "schema_version": "1.2.0",
  "timestamp": "ISO 8601",
  "note": "User's note/request about this area",
  "selected_area": { "x": 0, "y": 0, "width": 0, "height": 0 },
  "fullscreen_filename": "fullscreen.jpg",
  "area_filename": "area.jpg",
  "elements": [...]
}
```

### Single-element export

```json
{
  "schema_version": "1.2.0",
  "timestamp": "ISO 8601",
  "elements": [...]
}
```

### Element schema (shared)

```json
{
  "id": "UUID",
  "class_name": "UIImageView | UILabel | UIButton | etc.",
  "property_name": "the ivar/property name on the parent (e.g. imageView, titleLabel)",
  "cell_class_name": "the table/collection view cell class if inside a cell (e.g. CustomTableViewCell)",
  "view_controller_name": "the owning VC (e.g. HomeViewController)",
  "accessibility_identifier": "accessibility ID if set",
  "frame": { "x": 0, "y": 0, "width": 0, "height": 0 },
  "visual_properties": {
    "text": "label text if UILabel",
    "font_size": 12,
    "text_color": "#000000",
    "background_color": "#FFFFFF",
    "corner_radius": 0,
    "alpha": 1.0,
    "is_hidden": false,
    "image_name": "named image if UIImageView",
    "number_of_lines": 1,
    "content_mode": "scaleAspectFit"
  },
  "annotation": "user's annotation for this element",
  "screenshot_filename": "{id}.jpg or null"
}
```

## How to use this data

### Locating the code to change

The export tells you exactly where the code lives — go directly to the source file. Do not search the codebase when the export gives you `view_controller_name` or `cell_class_name`.

1. **`cell_class_name`** (e.g., `CustomTableViewCell`) — go directly to this file. The view is configured here.
2. **`view_controller_name`** (e.g., `HomeViewController`) — if no cell class, go directly to this file.
3. **`property_name`** (e.g., `titleLabel`) — once you've opened the file, find this property to locate where it's created and styled.
4. **`class_name`** (e.g., `UILabel`) — the view's type. Useful for understanding what kind of component it is.

Only fall back to searching if the file doesn't exist at the expected path or the property isn't found in the identified file.

### Interpreting the user's intent

- If the `note` field has a request (e.g., "make this bigger", "this looks wrong"), treat it as the task
- If individual elements have `annotation` fields, those describe per-element changes
- If no note/annotation, the user will likely follow up with what they want changed — use the export as context
- The screenshots show what the UI currently looks like; the JSON tells you exactly what code produces it

### Making changes

- Use `visual_properties` to understand current styling before modifying
- Use `frame` data to understand layout and spacing between elements
- When multiple elements share the same `cell_class_name`, they're likely instances of the same cell in a list — changes to the cell class affect all of them
- Always read the source file before editing to understand the full context

## Edge cases

- **Same `property_name` across multiple elements**: Multiple instances of the same cell type. The cell class is the same — you only need to change it once.
- **Missing `cell_class_name`**: The view is not inside a collection/table view cell. It's likely a direct subview of the view controller's view.
- **Missing `property_name`**: The view wasn't stored as a named property — it may be created inline or be a system view. Check the view controller for views matching the `class_name` and `frame`.
- **Elements with `is_hidden: true` or `alpha: 0`**: Invisible but still in the hierarchy. The user probably isn't asking about these unless they specifically mention hidden views.
- **Very large frames** (close to full screen size): Likely container views or navigation chrome — focus on the smaller, more specific elements.
- **No elements in export**: The selected area might not contain any custom views, or the selection missed the target. Let the user know.

## After reading the export

1. Summarize what you see: which screen, which component(s), what the current state is
2. If there's a note with a request, proceed to locate the relevant source code and plan the change
3. If no note/request, describe what you found and ask the user what they'd like to change
4. Always confirm which file(s) you'll modify before making edits
