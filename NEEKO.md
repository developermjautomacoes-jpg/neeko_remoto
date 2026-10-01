# NEEKO - Acesso Remoto

Versão personalizada do [RustDesk](https://github.com/rustdesk/rustdesk) 1.5.0 para a Neeko Automações Inteligentes.

- Servidor próprio: `2.24.68.119` (hbbs/hbbr), chave pública embutida em `libs/hbb_common/src/config.rs`
- Duas versões, escolhidas na compilação pela variável `NEEKO_VARIANT`:
  - `cliente`: somente receber acesso (vai para o computador do cliente)
  - `tecnico`: versão completa, para a equipe de suporte
- Compilação: Actions > **NEEKO - Compilar Windows** > Run workflow

Licença: AGPL-3.0, a mesma do projeto original (ver `LICENCE`). O código-fonte desta versão fica disponível neste repositório.
