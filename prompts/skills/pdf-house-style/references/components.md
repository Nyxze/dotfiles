# Component catalogue

Read this reference when a PDF needs a standard component. Choose the form that helps the reader answer the immediate question; do not copy the gallery's placeholder content into a real document.

| Need | Component | Example in the gallery |
| --- | --- | --- |
| Show exact values or categories | Text table | Tables |
| Show an image, photograph, or screenshot | Local image with caption | Image |
| Show an ordered change or a category comparison | SVG line or bar chart with units and legend | Chart |
| Show steps or relationships | SVG diagram | Diagram |
| Preserve aligned technical evidence | Fenced text or code block | Code and notes |
| Highlight a brief qualification | Blockquote callout | Code and notes |

## Tables

Use Markdown tables so text remains selectable. Keep the header short and repeat the unit in a column label when values share one.

```md
### Table 1: Example comparison

| Category | Value | Note |
| --- | ---: | --- |
| A | 12 | Example |
| B | 18 | Example |
```

## Images

Keep the source file next to the document or in a relative `figures/` folder. Use alt text that identifies the visual. The stylesheet limits images to the text width and 155 mm height.

```md
### Figure 1: Example image

![Abstract example image](figures/example.png)
```

## Charts and diagrams

Use the image pattern above with an SVG file. Choose lines for ordered change and bars for discrete category comparison. Charts need labeled axes and units where relevant. Diagrams need readable labels and a clear reading direction. Use Poppins for SVG text and the colors in `../assets/report.css`.

```md
### Figure 2: Example chart

![Two generic series across four categories](figures/chart.svg)
```

## Code, traces, and aligned text

Use a fenced block with an appropriate language tag. For long evidence, keep all necessary lines and inspect the page break; the renderer tries to keep a block intact.

````md
### Figure 3: Example text record

```text
Key   : Alpha
Value : 12
```
````

## Callouts

Use a blockquote for one short qualification. Avoid stacking several callouts or using them as a substitute for ordinary paragraphs.

```md
> Note: this is an illustrative example.
```
