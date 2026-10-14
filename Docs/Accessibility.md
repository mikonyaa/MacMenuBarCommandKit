# Accessibility

Rows combine title/subtitle/shortcut and expose selected traits. Keyboard selection requests a VoiceOver announcement; typed outcomes announce Succeeded/Failed and carry visible text/icons. Legacy informational summaries use a neutral icon. Actual audible VoiceOver behavior remains a separate gate in [native acceptance](NativeAcceptance.md).

While the palette is open, its background is disabled, stops hit testing and is hidden from accessibility. A modal trait alone is not accepted as proof of a complete focus trap. The native text field's delegate handles reserved arrows/Return/Escape while leaving normal editing and IME behavior native. Focus restoration targets the previous control (including field-editor ownership), checks its window and avoids overriding a new key window or attached sheet. A queued focus request checks current presentation before running.

Keyboard scroll is immediate, including Reduce Motion. Overlay transition animation reads Reduce Motion. Semantic colors/materials and text remain; no new theme is introduced. Public GrabScrollView remains compatible, but built-in surfaces use native ScrollView. No retention leak is inferred from source.

## Required interactive evidence

- 100 rows: held Down, visible selection, one correct Return; narrowing/no-match/removal/reorder, hover → keys and Escape.
- Tab/Shift-Tab and VoiceOver rotor cannot invoke/reach background content while modal.
- Escape returns input to the previous control; opening an editor/Settings leaves focus with that new surface.
- VoiceOver speaks selection and outcome; failure and samples are distinguishable without color.
- Reduce Motion/Transparency, high contrast, long text and light/dark readability.
- Actual status-item activation and window/menu shortcuts after main closes.

Controlled hosted native fixtures are recorded separately from full XCUI and manual VoiceOver. A focus test skips explicitly if its hosted process cannot obtain a key window; it is not a pass.
