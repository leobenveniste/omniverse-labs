# Workspace Guidelines & Rules

## UI/UX Pro Max: Design Intelligence & Code Refactor Protocol
ALWAYS enforce the following protocol when designing, creating, or modifying any UI/UX across this workspace:

1. **The Structural Layout Grid**:
   - Align all padding, margins, gaps, and heights to a strict 4px or 8px vertical/horizontal scale (e.g. 4, 8, 12, 16, 24, 32). Never use arbitrary or odd numbers.
   - Favor constraint-driven, flexible auto-layouts (Flex/Column/Row) over absolute positioning.
2. **Typography & Visual Hierarchy**:
   - Limit interface views to a maximum of 3 font weights and 4 distinct type sizes.
   - Enforce WCAG AA contrast ratios (minimum 4.5:1 for standard text, 3:1 for large text).
   - Ensure primary CTAs have prominent visual weight over secondary actions.
3. **Interactive States & Motion**:
   - Include smooth transitions, micro-interactions, and appropriate feedback (e.g., haptic feedback on mobile).
   - Define styles for all interactive states (hover, focus, pressed/active, disabled).
4. **Execution Workflow for UI Changes**:
   - **Phase 1**: Heuristic Audit Report (table mapping line, issue, severity, guideline).
   - **Phase 2**: Design Systems & Tokens (deliberate typography, color tokens, spacing).
   - **Phase 3**: Production Code Refactor (preserve all business logic/data hooks; use semantic tags and accessibility labels/tooltips for icon buttons).
