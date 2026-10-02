# SmartRoad

SmartRoad es una aplicación Android desarrollada con Flutter para recibir, procesar y notificar incidentes generados por el dispositivo SDA.

## Arquitectura vigente

- El backend se alojará en Google Cloud.
- Firebase Authentication gestiona la identidad.
- Firebase Realtime Database es la fuente de datos de la aplicación.
- Firebase Cloud Messaging entrega las notificaciones.
- El consumidor MQTT persistente y el webhook HTTP de Iridium/Ground Control son componentes backend separados que convergen en el mismo modelo canónico de incidentes.

La infraestructura concreta y su despliegue se definirán e implementarán en la fase 8 del plan.

## Documentación normativa

- [Manual vigente del SDA](manual-sda%20(4).html): referencia versionada del dispositivo.
- [Contrato del dispositivo](docs/device_contract.md): contrato que debe consumir el software.
- [Arquitectura](docs/ARCHITECTURE.md): arquitectura objetivo.
- [Alcance del MVP](docs/MVP_SCOPE.md): alcance aprobado.
- [Plan de implementación](docs/IMPLEMENTATION_PLAN.md): fases de implementación.
- [Reglas de trabajo](AGENTS.md): reglas permanentes.

`manual-sda.html` y cualquier manual anterior se conservan únicamente como antecedentes históricos. No deben utilizarse para definir comportamiento vigente cuando contradigan a `manual-sda (4).html`.
