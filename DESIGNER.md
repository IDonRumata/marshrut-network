# Designer handoff — Маршрут

Дизайнер-редактор работает в Figma, я переношу её изменения в код.

## Figma-файл

**[Маршрут — Design System](https://www.figma.com/design/yQZaqa22PTjQhEADvrOfOT)**

Две страницы:

### 📐 Design System
Дизайн-токены и базовые компоненты:
- **Цветовая палитра** — 8 цветов (Ink, Road, Asphalt, Headlight, Fog, Smoke, Mile, White) с hex и описанием каждого назначения
- **Типографика** — 8 размерных классов (Display 60px → Caption 14px) на трёх шрифтах: Playfair Display, Inter, JetBrains Mono
- **Spacing scale** — 8/16/24/32/48/64/96 px (привязка к `var(--space-N)`)
- **Компоненты** — Buttons (primary, ghost, на тёмном), Chapter Card, Diary Card

### 🏠 Pages
Макеты основных страниц сайта:
1. **Home** (1440×~2400px) — Hero + Status + Manifesto + Book preview + Email + Diary preview + Footer
2. **Book catalog** (`/book/`) — заголовок с прогресс-баром + grid из 3 chapter card
3. **Chapter** (`/book/[slug]/`) — узкая колонка чтения (680px), prev/next navigation
4. **Diary** (`/diary/`) — список записей с date column

Слева от макетов — **Designer Brief** в красной рамке.

## Source of truth

Дизайн-токены живут в коде: `packages/design-tokens/src/tokens.json`.
Любая правка цвета/шрифта/spacing в Figma должна синхронизироваться с этим
файлом. Маленькие правки (например, оттенок цвета) — комментарий в Figma,
я переношу.

## Workflow

```
Дизайнер правит в Figma
   ↓ Figma Comments на фрейме
Я смотрю комментарии
   ↓ переношу в код
git commit + push
   ↓ CI деплоит
Live на marshrut.eu
```

**Дизайнер не пушит в код.** Все правки только через Figma + комментарии.

## Принципы дизайна

- **Тон:** честный, немного суровый. Это личный дневник, не корпоратив.
- **Чтение длинного текста:** Playfair Display, 20px, line-height 1.8.
  Не менять на sans для глав книги.
- **Headlight `#E94560`** — только акценты, CTA, активные состояния.
  Не для больших площадей.
- **Mobile-first.** Большинство читателей с телефона.
- **Карточки:** лёгкие тени, тонкие границы. Без glassmorphism, без неона.

## Live preview

- Локально: запусти `pnpm dev` из `apps/flagship/` → http://localhost:4321
- Прод: будет на https://marshrut.eu после деплоя

## Контакт

Через комментарии в Figma. Андрею в Telegram — он передаст мне.
