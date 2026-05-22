# Маршрут — Network

Экосистема контентных сайтов проекта **Маршрут**. Личный бренд Андрея Мороза и
четыре нишевых проекта (личный бренд, питание, финансы, путешествия), построенные
на единой архитектуре.

> 🛣 Дальнобойщик, который пишет код между рейсами. Книга, дневник, инструменты.
> Всё открыто.

## Архитектура

Монорепо на **pnpm workspaces**. Каждый сайт — отдельное Astro-приложение,
переиспользует общие пакеты: UI-компоненты, дизайн-токены из Figma,
контент-пайплайн, SEO-утилиты.

```
marshrut-network/
├── apps/
│   ├── flagship/         marshrut.eu — личный бренд (текущая итерация)
│   ├── health/           health.marshrut.eu — здоровое питание
│   ├── finance/          finance.marshrut.eu — финансы EU
│   └── travel/           travel.marshrut.eu — эмиграция, путешествия
├── packages/
│   ├── ui/               общие компоненты Astro
│   ├── design-tokens/    цвета, типографика — синхронизация с Figma
│   ├── content-pipeline/ Notion → markdown → HTML
│   └── seo/              Schema.org, llms.txt, sitemap
└── infra/
    ├── docker/           Dockerfile, docker-compose.yml, nginx.conf
    └── scripts/          deploy.sh, setup-server.sh
```

## Стек

- **SSG:** Astro 5
- **Менеджер пакетов:** pnpm
- **Контент:** markdown в репо (single source of truth), Notion как UI для авторов
- **Email:** Listmonk (self-hosted)
- **Аналитика:** Plausible (cookieless, GDPR-compliant)
- **CDN:** Cloudflare Free
- **Хостинг:** Hetzner Cloud CX22, Falkenstein (DE)
- **CI/CD:** GitHub Actions
- **TLS:** TLS 1.3 + гибридная связка X25519MLKEM768 (пост-квантовая криптография)

## Корпоративные стандарты

Все проекты следуют [корпоративному стандарту разработки](https://github.com/IDonRumata)
владельца:
- Никаких хардкодных секретов
- Все внешние API через retry с timeout
- Type-safe код (TypeScript строгий)
- Структурированное логирование
- PQC-готовность (NIST FIPS 203/204/205)

## Лицензия

Код — MIT. Контент (книга, дневник, статьи) — © Андрей Мороз, все права защищены.
