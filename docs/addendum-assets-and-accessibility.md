# Addendum: Brand Asset Creation & Accessibility Requirements

## Updates to Implementation Plan v2

This document covers two things you asked about:
1. **Accessibility** — What the color system needs to be fully WCAG compliant
2. **Design tooling** — What software to use alongside Claude Code/OpenClaw for professional brand assets

---

## Part 1: Fully Accessible Color System

### Why This Matters for SEO

Accessibility isn't just ethical — it directly impacts SEO. Search engines factor in user experience signals, and inaccessible sites cause higher bounce rates, shorter session times, and lower engagement. Google's Core Web Vitals and page experience signals reward sites that are usable by everyone. Beyond that, ADA compliance lawsuits have been increasing year over year — building accessible from day one avoids costly retrofitting.

### What the Plugin Must Enforce

The brand-reference.yml color section needs to be upgraded from simple hex values to a full accessibility-first color system:

**WCAG 2.2 Contrast Requirements:**

| Element | Minimum Ratio | WCAG Level |
|---------|--------------|------------|
| Body text (under 18px) on background | 4.5:1 | AA (required) |
| Large text (18px+ or 14px bold) on background | 3:1 | AA (required) |
| UI components & graphical objects | 3:1 | AA (required) |
| Body text on background (enhanced) | 7:1 | AAA (recommended) |
| Large text on background (enhanced) | 4.5:1 | AAA (recommended) |

**What the plugin should generate for every color:**

```yaml
colors:
  primary:
    - name: "Brand Blue"
      hex: "#2563EB"
      rgb: "37, 99, 235"
      hsl: "217, 91%, 60%"
      use: "Primary CTA, links, key UI elements"

      # Full tint/shade scale (8-10 steps)
      scale:
        50:  "#EFF6FF"   # Lightest — backgrounds, hover states
        100: "#DBEAFE"
        200: "#BFDBFE"
        300: "#93C5FD"
        400: "#60A5FA"
        500: "#3B82F6"   # Base
        600: "#2563EB"   # ← Primary brand color
        700: "#1D4ED8"
        800: "#1E40AF"
        900: "#1E3A8A"   # Darkest — text on light bg

      # Pre-computed contrast pairs
      accessible_pairs:
        - foreground: "#2563EB"     # Brand Blue
          background: "#FFFFFF"      # White
          contrast_ratio: 4.56
          wcag_aa_normal: true       # ≥ 4.5:1
          wcag_aa_large: true        # ≥ 3:1
          wcag_aaa_normal: false     # ≥ 7:1
          wcag_aaa_large: true       # ≥ 4.5:1
          use: "Blue buttons on white, blue links on white"

        - foreground: "#FFFFFF"
          background: "#2563EB"
          contrast_ratio: 4.56
          wcag_aa_normal: true
          use: "White text on blue buttons"

        - foreground: "#1E3A8A"      # Blue 900
          background: "#EFF6FF"       # Blue 50
          contrast_ratio: 10.3
          wcag_aaa_normal: true
          use: "Dark blue text on light blue background"

      # Color blindness safety
      colorblind_notes:
        protanopia: "Distinguishable — no red component"
        deuteranopia: "Distinguishable — no red component"
        tritanopia: "May appear similar to purple — pair with shape/icon cues"
```

**Additional accessibility rules the plugin must follow:**

1. Never rely on color alone to convey meaning — always pair with icons, labels, or patterns
2. Every semantic color (success/warning/error) must have an icon alternative
3. Focus states must have 3:1 contrast against adjacent colors
4. All color pairs used in the brand must be pre-validated — no guessing at implementation time
5. Provide dark mode variants with validated contrast ratios
6. Flag problematic combinations: red/green, yellow/white, light gray/white

### Tools the Plugin Should Use for Validation

The plugin's `typography-color` skill should instruct Claude to:

1. Generate the full tint/shade scale for each brand color
2. Compute contrast ratios for every intended pairing
3. Flag any pair that fails AA
4. Suggest the nearest accessible alternative for any failing pair
5. Test against the three main types of color vision deficiency
6. Output a contrast matrix (like EightShapes Contrast Grid format)

### Recommended External Validation Tools

These should be listed in the brand manual as "verify with" references:

| Tool | What It Does | URL |
|------|-------------|-----|
| WebAIM Contrast Checker | Quick ratio check for any two colors | webaim.org/resources/contrastchecker |
| EightShapes Contrast Grid | Matrix of all color-vs-color combinations | contrast-grid.eightshapes.com |
| Accessible Palette | Build CIELAB-based scales with guaranteed contrast | accessiblepalette.com |
| InclusiveColors | Full palette builder with live WCAG validation | inclusivecolors.com |
| Adobe Color Contrast Checker | Check ratios + colorblind simulation | color.adobe.com/create/color-contrast-analyzer |
| Stark (Figma plugin) | In-Figma contrast checking and colorblind sim | getstark.co |
| Color Safe | Generate accessible text colors for any background | colorsafe.co |

---

## Part 2: Logo & Brand Asset Design Workflow

### The Reality Check

Based on research, here's the honest state of affairs in early 2026:

**What Claude Code / OpenClaw CAN do well:**
- Generate SVG logos (geometric marks, wordmarks, monograms, abstract shapes)
- Produce multiple variations quickly (25+ concepts in minutes)
- Create favicon sizes, social media adaptations, dark/light variants
- Build comprehensive preview pages showing logos in real-world context
- Generate complete brand asset packages (business cards, letterheads, social templates)
- Write the SVG code directly — infinitely scalable, production-ready vector format

**What Claude Code / OpenClaw CANNOT do (or does poorly):**
- Complex illustration-style logos (detailed mascots, intricate hand-drawn looks)
- Photorealistic imagery or raster-based brand assets
- Print production files in CMYK with spot colors
- Pixel-perfect refinement that a human designer would do in Illustrator
- Trademark-safe verification (it can't check if a logo is too similar to existing marks)

### Recommended Software Stack

Here's what you need alongside Claude Code/OpenClaw, organized by role:

#### Tier 1: Essential (you need these)

**Figma** (Free plan works)
- Role: Design system hub, component library, logo refinement, layout design
- Why: Industry standard, collaborative, exports SVG/PNG/PDF
- AI integration: Claude Code can talk to Figma directly via MCP or CLI tools
- One person found that connecting Claude Code to Figma through DevTools (no MCP needed) was faster and burned fewer tokens
- Use for: Refining AI-generated logos, building the design system, creating mockups

**SVG (generated by Claude Code)**
- Role: Primary logo format — infinitely scalable vectors
- Why: Claude Code excels at writing SVG code directly
- There's a dedicated slash command (/design-logo) that generates 25 diverse SVG concepts, builds preview pages with real-world mockups (nav bars, browser frames, mobile screens, favicons), and runs a feedback loop for refinement
- Use for: Initial logo generation, all web-ready assets

#### Tier 2: Recommended (significantly improves quality)

**Adobe Illustrator** (Paid — ~$23/month)
- Role: Professional vector refinement, print production files
- Why: When you need CMYK output, spot colors, or EPS files for print
- Use for: Final logo cleanup, creating print-ready versions, professional refinement
- Alternative: Affinity Designer 2 ($70 one-time) — does 90% of what Illustrator does

**Weavy AI or Flux Pro** (for image generation)
- Role: Generate raster brand imagery — photography style, textures, backgrounds
- Why: Claude Code produces code (SVG, HTML, CSS) but not photographic imagery
- Use for: Hero images, social media imagery, texture/pattern generation, mood boards
- Workflow: Use Claude to write the image generation prompts, then run them in Weavy/Flux

**Canva** (Free or Pro at $13/month)
- Role: Quick social media assets, presentations, templates
- Why: Has a direct Claude integration — Claude can create and edit Canva designs within the conversation, pulling from your brand kit
- Use for: Social media templates, quick marketing materials, non-designer team members

#### Tier 3: Nice to Have

**Stark** (Figma plugin — free tier available)
- Role: Accessibility checking inside Figma
- Why: Validates contrast ratios and simulates color blindness on your actual designs

**Font source: Google Fonts / Adobe Fonts / Fontshare**
- Role: Typography selection and licensing
- Why: Need properly licensed fonts for web and print use
- Key consideration: Choose fonts with good language support and multiple weights

**Coolors.co or Accessible Palette**
- Role: Color palette generation and accessibility validation
- Why: Quick way to explore palettes before locking them in brand-reference.yml

### The Logo Design Process (What the Plugin Should Guide)

The `/brand:generate` command should walk through this sequence for logo creation:

```
Phase 1: Discovery (Claude interview)
├── Business name, industry, competitors
├── Keywords that describe the brand personality
├── Preferences: icon-only? wordmark? combination? abstract?
├── Reference logos you like (upload screenshots)
└── Colors already decided or open to suggestions?

Phase 2: Concept Generation (Claude Code / SVG)
├── Generate 20-25 diverse SVG concepts
├── Mix of: lettermarks, abstract marks, wordmarks, combination marks
├── Mix of shapes: circles, shields, hexagons, organic, geometric
├── Each concept in both dark-on-light and light-on-dark
└── Present on a preview page with real-world mockups

Phase 3: Refinement (Narrow to 3-5)
├── User picks favorites
├── Claude generates 3-4 variations of each pick
├── Test at multiple sizes: hero (200px+), nav (40px), favicon (16px)
├── Test on photography backgrounds, colored backgrounds, white, dark
└── Simplify icon variants for small sizes

Phase 4: Finalization
├── Lock the chosen logo
├── Generate all required variants:
│   ├── Full color (primary)
│   ├── Reversed / white (for dark backgrounds)
│   ├── Monochrome / black
│   ├── Icon-only mark (for favicons, app icons)
│   └── Horizontal and stacked layouts (if combination mark)
├── Define clear space rules and minimum sizes
├── Create misuse examples (stretched, wrong colors, busy bg, etc.)
└── Export: SVG (master), PNG (@1x, @2x, @3x), ICO (favicon)

Phase 5: Professional Refinement (Optional — outside Claude)
├── Import SVGs into Figma or Illustrator
├── Clean up curves and anchor points
├── Finalize kerning and letter spacing in wordmarks
├── Create CMYK / Pantone versions for print
├── Run trademark similarity search (manual or tool-assisted)
└── Export final production files: AI, EPS, PDF, SVG, PNG
```

### What to Provide Claude for Best Logo Results

Based on what people have found works best:

1. **Upload visual references** — Screenshots of logos you like work far better than verbal descriptions. "Match this visual approach" is more effective than trying to describe a style.
2. **Describe what it should NOT be** — "Not corporate, not playful, not hand-drawn" narrows the space faster than positive descriptions alone.
3. **Provide the brand personality first** — Run the tone-of-voice skill BEFORE logo generation. A logo for a "confident, warm, clear" brand will look very different from a "bold, disruptive, technical" one.
4. **Always test at small sizes** — A logo that looks great at 200px often falls apart at 16px (favicon). The plugin should mandate this check.
5. **Keep SVG as the master format** — You can always render to any size or format from SVG. Never start with raster.
6. **Use extended thinking** — Turn on extended thinking for higher-quality file creation.

---

## Summary of Changes to Implementation Plan v2

### Updated brand-reference.yml schema:
- Colors section now includes full tint/shade scales (50-900)
- Every color pair gets pre-computed contrast ratios
- WCAG AA and AAA pass/fail for both normal and large text
- Colorblind safety notes per color
- Dark mode color variants with validated contrast

### Updated plugin skills:
- `typography-color` skill now includes accessibility validation as a core step (not optional)
- `visual-identity` skill now includes the 5-phase logo design process
- New recommendation: run tone-of-voice BEFORE visual-identity (personality informs aesthetics)

### New section in brand manual:
- "Color Accessibility Reference" page with contrast matrix
- "Logo Variants" page showing all sizes and backgrounds
- "Design Tool Setup" page listing recommended software and how to import brand assets

### Updated skill execution order:
```
/brand:generate flow (revised):

1. Brand identity interview (mission, values, positioning)
2. Audience & personas
3. Tone of voice & messaging          ← personality defined here
4. Color palette (with full accessibility validation)
5. Typography system
6. Visual identity & logo design       ← informed by personality + colors
7. Content rules
8. Social media guidelines
9. Compile → brand-reference.yml + brand-manual.docx
```

The key change: **voice and personality come before visual design**. The brand's character should drive the aesthetics, not the other way around.
