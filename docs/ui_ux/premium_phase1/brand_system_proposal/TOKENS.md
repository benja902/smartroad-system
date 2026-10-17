# Catálogo de tokens semánticos · v1.0 propuesta

**Pendiente de aprobación.** Este JSON y catálogo solo sirven al prototipo documental. La futura fuente de ejecución será `lib/core/theme/` y `AppTheme`; no se importarán como sistema paralelo.

## Color

| Rol | Valor candidato |
|---|---|
| `brand.navy` | `#031B3B` |
| `brand.aqua` | `#14E0D3` |
| `action.primary` | `#031B3B` |
| `action.onPrimary` | `#FFFFFF` |
| `action.secondary` | `#006D68` |
| `action.onSecondary` | `#FFFFFF` |
| `action.secondaryContainer` | `#CCF7F3` |
| `action.onSecondaryContainer` | `#031B3B` |
| `focus.ring` | `#006D68` |
| `surface.canvas` | `#F8F9FA` |
| `surface.base` | `#FFFFFF` |
| `surface.subtle` | `#EDF3F5` |
| `text.primary` | `#1B1B1E` |
| `text.heading` | `#031B3B` |
| `text.secondary` | `#44474D` |
| `border.decorative` | `#C5C6CE` |
| `border.control` | `#75777E` |
| `status.success.accent` | `#2ECC71` |
| `status.success.text` | `#176B50` |
| `status.success.surface` | `#EAF5EF` |
| `status.warning.accent` | `#F39C12` |
| `status.warning.text` | `#80520A` |
| `status.warning.surface` | `#FFF4DE` |
| `status.critical.accent` | `#E74C3C` |
| `status.critical.text` | `#B52F34` |
| `status.critical.surface` | `#FFF0EE` |
| `status.unknown.text` | `#44474D` |
| `status.unknown.surface` | `#EDF3F5` |
| `feedback.error.text` | `#B52F34` |
| `feedback.error.surface` | `#FFF0EE` |
| `disabled.text` | `#526078` |
| `disabled.surface` | `#E3E8EF` |
| `action.pressed` | `#0B355B` |
| `action.critical` | `#B52F34` |
| `action.warning` | `#80520A` |
| `border.error` | `#B52F34` |
| `icon.default` | `#44474D` |
| `selection.text` | `#031B3B` |
| `selection.surface` | `#CCF7F3` |

## type

| Token | Valor candidato |
|---|---|
| `family` | `"Manrope"` |
| `title` | `[28, 34]` |
| `criticalTitle` | `[32, 40]` |
| `section` | `[20, 28]` |
| `body` | `[16, 24]` |
| `support` | `[14, 20]` |
| `navigation` | `[12, 16]` |
| `weights` | `{"title": 800, "section": 700, "body": 500, "support": 400, "label": 600, "navigation": 600}` |
| `loginTitle` | `[32, 40]` |
| `label` | `[14, 20]` |

## space

| Token | Valor candidato |
|---|---|
| `scale` | `[4, 8, 16, 24, 32, 48]` |
| `edge` | `20` |
| `gutter` | `12` |
| `contentMax` | `600` |

## radius

| Token | Valor candidato |
|---|---|
| `small` | `4` |
| `base` | `8` |
| `auxiliary` | `12` |
| `control` | `16` |
| `hero` | `24` |

## elevation

| Token | Valor candidato |
|---|---|
| `flat` | `0` |
| `overlayCandidate` | `2` |

## icon

| Token | Valor candidato |
|---|---|
| `family` | `"existing Material Icons"` |
| `default` | `24` |
| `touchTargetMin` | `48` |
| `reference` | `"Lucide outlined, visual reference only; no package adopted"` |
| `strokeReference` | `1.8` |
| `small` | `20` |
| `semantic` | `32` |

## motion

| Token | Valor candidato |
|---|---|
| `responseMs` | `120` |
| `selectionMs` | `180` |
| `entranceMs` | `240` |
| `localChangeMs` | `180` |
| `criticalDelayMs` | `0` |
| `reducedDecorativeMs` | `0` |
| `curveResponse` | `"easeOutCubic"` |
| `brandTimeline` | `"Variante D 4440 ms de referencia; aprobada DEV, no espera obligatoria"` |
| `curveSelection` | `"easeInOutCubic"` |
| `curveEntrance` | `"easeOutCubic"` |
| `formLabelMs` | `120` |
| `replayOnDataUpdate` | `false` |

## Correspondencia Flutter y estados

| Familia | Destino existente | Estado/uso |
|---|---|
| Marca/acción/superficie/texto | `AppColors`, `ColorScheme` | Navy único; aqua solo acento, teal interactivo. |
| Estado operativo/atención/crítico | Roles explícitos, `StatusPill`, banners | Texto, superficie y acento separados; no cambiar clasificación. |
| Error UI | `ColorScheme.error`, `InputDecorationTheme` | No es severidad de incidente. |
| Tipografía | `AppTypography`, `TextTheme` | sp escalables, peso y línea explícitos. |
| Espacio/radio/elevación | `AppSpacing`, `AppRadius`, `AppShadows` | Reutilizar escala actual; no theme paralelo. |
| Botón | Temas Elevated/Outlined/Text y widgets actuales | Normal, pulsado, foco, ocupado, deshabilitado; acción no espera motion. |
| Campo | `InputDecorationTheme`, TextFormField existente | Reposo, foco, lleno, error y deshabilitado; ayuda/error aumentan alto. |
| Motion | `ScreenEntrance`/Material y transiciones locales | Reusar lo existente; decoración reducida 0, demora crítica 0. |

`action.pressed` es un rol candidato explícito; los estados Material podrán derivarse mediante state layers y deberán medirse sobre el fondo final. No superponer alpha sin revisar contraste. La muestra congelada de una pantalla representa estado ordinario aunque sus controles se deshabiliten técnicamente para revisión. El catálogo muestra por separado el estado visual deshabilitado.
