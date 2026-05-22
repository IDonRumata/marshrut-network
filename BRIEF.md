# BRIEF — Marshrut Network

> Полная архитектура и текущее состояние проекта.
> Этот файл — источник правды между сессиями. Обновляется при изменении архитектуры.

## Что это

Контентная экосистема **Маршрут**: 4 сайта на единой архитектуре.
Сейчас разрабатывается флагман — **marshrut.eu**, личный бренд Андрея Мороза
(автор-дальнобойщик из Беларуси, строит жизнь в EU через AI-кодинг).

Источник полной архитектуры: ТЗ v2.0 (Human-in-the-Loop пайплайн Notion →
редактор → сайт → соцсети).

## Стек

| Слой | Технология | Версия |
|---|---|---|
| Менеджер пакетов | pnpm workspaces | 11.x |
| Runtime | Node | 22 LTS |
| SSG | Astro | 5.x |
| Контент | markdown в репо + Notion как UI | — |
| Хостинг | Hetzner Cloud CX22 (Falkenstein DE) | — |
| Reverse proxy / TLS | Caddy | 2.8+ |
| TLS | TLS 1.3 + X25519MLKEM768 (PQC) | NIST FIPS 203 |
| Email-рассылка | Listmonk (self-hosted) | latest |
| Аналитика | Plausible (опциональный профиль) | latest |
| CDN | Cloudflare Free | — |
| CI/CD | GitHub Actions | — |
| Git хостинг | GitHub | — |

## Репозитории

- **marshrut-network** (public): https://github.com/IDonRumata/marshrut-network — код, инфра, опубликованный контент
- **marshrut-drafts** (private): https://github.com/IDonRumata/marshrut-drafts — черновики книги до публикации

## Структура

```
marshrut-network/
├── apps/
│   └── flagship/             marshrut.eu — Astro SSG
│       ├── astro.config.mjs
│       ├── src/
│       │   ├── content.config.ts   контентные коллекции (book, diary)
│       │   ├── content/{book,diary}/  markdown главы и записи
│       │   ├── layouts/Base.astro
│       │   ├── pages/index.astro
│       │   └── styles/global.css
│       └── public/{robots.txt,llms.txt}
├── packages/
│   ├── design-tokens/        источник дизайн-токенов (JSON → CSS)
│   │   ├── src/tokens.json
│   │   ├── scripts/build.mjs
│   │   └── dist/{tokens.json,tokens.css}
│   ├── ui/                   общие компоненты (TBD)
│   ├── content-pipeline/     Notion → markdown (TBD)
│   └── seo/                  Schema.org, sitemap утилиты (TBD)
├── infra/
│   ├── docker/
│   │   ├── Dockerfile         multi-stage Astro build → Caddy
│   │   ├── Caddyfile          PQC TLS + headers + кеширование
│   │   ├── docker-compose.yml flagship + listmonk + plausible
│   │   └── .env.example
│   └── scripts/
│       └── setup-server.sh    первичная настройка Hetzner CX22
└── .github/
    ├── workflows/build.yml    CI: build + type check
    └── dependabot.yml         автообновление зависимостей
```

## Дизайн-токены

Источник правды: `packages/design-tokens/src/tokens.json`.
Билдится в `dist/tokens.css` (CSS-переменные) и `dist/tokens.json` (для импорта).

Категории: color, font, space, radius, shadow, breakpoint, content.

Палитра — "дорожный журнал номада":
- Ink `#1A1A2E` (текст)
- Road `#16213E` (hero фон)
- Asphalt `#0F3460` (глубокий акцент)
- Headlight `#E94560` (CTA)
- Fog `#F5F5F0` (бумажный фон)
- Smoke `#8892A4` (вторичный текст)
- Mile `#D4D8E2` (границы)

Шрифты: Playfair Display (заголовки serif), Inter (тело), JetBrains Mono (код/метаданные).

Figma-источник: https://www.figma.com/design/yQZaqa22PTjQhEADvrOfOT/Маршрут---Design-System
(страницы: Design System, Pages — задизайнить токены и компоненты вручную; токены в репо — текущий source of truth).

## Безопасность

- TLS 1.3 + X25519MLKEM768 (гибридный PQC) — Caddy 2.8 + Go 1.24 std lib
- HSTS preload, CSP, X-Frame-Options, Referrer-Policy
- Listmonk + Plausible БД — internal-only Docker сеть, без выхода наружу
- UFW: открыты только 22, 80, 443
- fail2ban на SSH
- root SSH отключен, пароль-аутентификация отключена
- Unattended-upgrades для security патчей
- GitHub secret scanning + push protection
- Dependabot weekly

## Юридический фундамент

- Сервер в Hetzner DE (GDPR-compliant)
- Listmonk хостится в EU
- План монетизации через польский ИП (JDG)
- Cloudflare DNS + CDN

## Текущий статус

- [x] GitHub репо созданы, защита включена
- [x] Монорепо скелет (pnpm workspaces)
- [x] Design tokens пакет (JSON + CSS build)
- [x] Astro app flagship — стартовая страница билдится
- [x] Docker + Caddy с PQC TLS
- [x] Listmonk + Plausible в compose
- [x] Setup-server.sh для Hetzner
- [x] GitHub Actions CI
- [ ] Figma — дизайн-система и макеты страниц (в работе)
- [ ] Hetzner CX22 — ждём верификацию аккаунта
- [ ] Регистрация домена marshrut.eu
- [ ] Cloudflare DNS
- [ ] Контентный пайплайн Notion → markdown
- [ ] UI-компоненты (Hero, ChapterCard, DiaryCard, EmailBlock)
- [ ] Тестовый контент (3 главы, 5 дневниковых, 8 ресурсов)
- [ ] Listmonk first run — настройка списка, шаблоны писем
