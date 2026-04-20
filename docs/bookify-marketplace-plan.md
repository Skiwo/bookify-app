# Bookify Marketplace — Implementation Plan

## Context

Bookify — это Norwegian B2B маркетплейс для найма фрилансеров, построенный поверх существующей инфраструктуры Payout Partner (POP). Текущая кодовая база (app) уже реализует POP-интеграцию для буккеров и фрилансеров. Задача — добавить маркетплейс-слой (шопы, клиенты, котировки, джобы) как **отдельные роуты**, не затрагивая существующие `/booker/*` и `/freelancer/*`.

**Правило:** Все новые функции — в отдельных namespace'ах. Существующие роуты/контроллеры/модели не изменяются (только расширяются там, где не ломается текущее поведение).

---

## Что уже есть

| Компонент | Файл | Назначение |
|---|---|---|
| `User` | `app/models/user.rb` | booker / freelancer роли |
| `Enrollment` | `app/models/enrollment.rb` | связь буккер → фрилансер |
| `Booking` / `BookingLine` | `app/models/booking.rb` | счёт + строки |
| `Payout` | `app/models/payout.rb` | POP payout record |
| `PopApiClient` | `app/services/pop_api_client.rb` | все POP API v2 вызовы |
| `/booker/*` | `app/controllers/booker/` | буккер-дашборд |
| `/freelancer/*` | `app/controllers/freelancer/` | фрилансер-дашборд |

---

## Архитектурное решение

Bookify добавляет **3 новых namespace**:

```
/shops/*          — публичный маркетплейс (без логина)
/shop/*           — кабинет владельца шопа
/client/*         — кабинет клиента (B2B организации)
```

Существующие `/booker/*` и `/freelancer/*` — **не трогаем**.

### Маппинг на POP-концепты (из презентации)

- Shop owner = фрилансер, enrolled в Bookify POP-аккаунте, у него есть Shop
- Roster member = другой фрилансер, enrolled в тот же POP-аккаунт
- Client = B2B организация (BRREG-верификация)
- Job = один Invoice с двумя типами строк: `work` (member) + `commission` (shop owner)

---

## Фазы реализации

---

## Phase 1 — MVP (запуск, ~1 неделя)

### 1.1 Модели

#### Новые модели

**`Shop`** — шоп фрилансера
```
id, slug (unique), name, description,
owner_id (FK → users),
status: draft / active / paused / closed,
visibility: public / private,
commission_percent (default: 5),
skill_tags (string array),
city,
created_at, updated_at
```

**`ShopMember`** — ростер шопа (invited roster members)
```
id, shop_id (FK → shops),
enrollment_id (FK → enrollments),   ← существующая модель, не изменяем
status: invited / active / inactive,
invited_at, accepted_at
```

**`Client`** — B2B клиент (Norwegian org)
```
id, user_id (FK → users, nullable для guest-flow),
org_number (BRREG),
org_name, org_address,
verified_at,
created_at, updated_at
```

**`Job`** — единица работы (замена Invoice в маркетплейсе)
```
id, shop_id, client_id,
assigned_member_id (FK → shop_members),
status: draft / quoted / accepted / in_progress / pending_confirmation /
        disputed / invoiced / paid / completed,
title, description,
work_amount_ore, commission_amount_ore,
quote_expires_at (now + 72h),
completion_marked_at, confirmation_deadline_at (now + 48h),
booking_id (FK → bookings, nullable — заполняется при invoicing),
created_at, updated_at
```

**`Message`** — чат (three-party: client, shop owner, member)
```
id, job_id, sender_id (FK → users), body,
created_at
```

#### Расширение существующих моделей (только additive, без изменения поведения)

**`BookingLine`** — добавить `line_type: commission` в enum
_(существующий enum: work/benefit/expense/diet — добавляем commission как новое значение)_

**`User`** — добавить `client` и `shop_owner` в role enum
_(существующий: booker/freelancer — добавляем, не ломаем)_

**`PopApiClient`** — добавить:
- `commission` line type в `create_payout`
- `source_params` JSONB параметр
- `payee_freelance_profile_id` на каждую строку

### 1.2 Роуты (новые, отдельные)

```ruby
# config/routes.rb — только добавляем, не трогаем существующие

# Публичный маркетплейс
scope '/shops' do
  get '/',           to: 'shops#index',   as: :shops
  get '/:slug',      to: 'shops#show',    as: :shop
  post '/:slug/requests', to: 'shop_requests#create', as: :shop_requests
end

# Skill category pages (SEO)
get '/nb/no/:skill', to: 'skill_pages#show', as: :skill_page

# Кабинет владельца шопа
namespace :shop do
  get  'dashboard',            to: 'dashboard#show'
  resource 'settings',         only: [:show, :update]
  resource 'shop_profile',     only: [:show, :edit, :update]
  resources 'members',         only: [:index, :new, :create, :destroy]
  resources 'jobs',            only: [:index, :show] do
    member do
      post 'issue_quote'
      post 'mark_complete'
    end
  end
  resources 'quotes',          only: [:new, :create, :show]
end

# Кабинет клиента
namespace :client do
  get  'dashboard',            to: 'dashboard#show'
  resource 'registration',     only: [:new, :create]
  resources 'requests',        only: [:index, :show]
  resources 'quotes',          only: [:index, :show] do
    member do
      post 'accept'
      post 'decline'
    end
  end
  resources 'jobs',            only: [:index, :show] do
    member do
      post 'confirm'
      post 'dispute'
    end
  end
end

# Общий чат (доступен всем трём сторонам)
resources :job_messages, only: [:create]
```

### 1.3 Контроллеры (новые)

```
app/controllers/
  shops_controller.rb            # index (listing), show (detail)
  shop_requests_controller.rb    # create (client submits request)
  skill_pages_controller.rb      # show (SEO category page)

  shop/
    base_controller.rb           # auth: shop_owner role
    dashboard_controller.rb
    settings_controller.rb
    shop_profile_controller.rb
    members_controller.rb
    jobs_controller.rb           # + issue_quote, mark_complete
    quotes_controller.rb

  client/
    base_controller.rb           # auth: client role
    dashboard_controller.rb
    registration_controller.rb   # BRREG verification
    requests_controller.rb
    quotes_controller.rb         # + accept, decline
    jobs_controller.rb           # + confirm, dispute

  job_messages_controller.rb
```

### 1.4 Ключевые flows

#### Flow A: Клиент отправляет запрос
1. `GET /shops/:slug` → ShopsController#show
2. `POST /shops/:slug/requests` → ShopRequestsController#create
   - Создаёт `Job` (status: draft), уведомляет shop owner

#### Flow B: Shop owner выпускает котировку
1. `GET /shop/jobs` → список входящих запросов
2. `GET /shop/quotes/new?job_id=X` → форма котировки
3. `POST /shop/quotes` → QuotesController#create
   - Обновляет Job (status: quoted, quote_expires_at = now+72h)
   - Уведомляет клиента

#### Flow C: Клиент принимает котировку
1. `GET /client/quotes/:id` → просмотр котировки
2. `POST /client/quotes/:id/accept` → QuotesController#accept
   - Job status → accepted → in_progress
   - Открывает чат

#### Flow D: Завершение и invoicing
1. Любая сторона: `POST /shop/jobs/:id/mark_complete` или `/client/jobs/:id/confirm`
2. После подтверждения (или через 48h тишины):
   - Создаётся `Booking` + `BookingLine` (work + commission)
   - Вызов `PopApiClient#create_payout` с двумя строками
   - Job status → invoiced

#### Flow E: Регистрация клиента
1. `GET /client/registration/new` → форма с org_number
2. `POST /client/registration` → BRREG lookup → создание Client

### 1.5 POP API расширения (в `pop_api_client.rb`)

```ruby
# Добавить commission line type поддержку
# Добавить source_params JSONB
# Добавить payee_freelance_profile_id на каждую строку invoice
```

### 1.6 Views (HAML)

```
app/views/
  shops/
    index.html.haml    # Grid шопов, фильтр по городу/скилу
    show.html.haml     # Детальная страница шопа + форма запроса
  skill_pages/
    show.html.haml     # SEO страница навыка, список шопов

  shop/
    dashboard/show.html.haml
    jobs/index.html.haml, show.html.haml
    quotes/new.html.haml, show.html.haml
    members/index.html.haml, new.html.haml

  client/
    dashboard/show.html.haml
    registration/new.html.haml
    quotes/index.html.haml, show.html.haml
    jobs/index.html.haml, show.html.haml

  job_messages/
    _message.html.haml   # Turbo Stream частичный шаблон
```

---

## Phase 2 — Post-launch (по приоритету после MVP)

### 2.1 Chat (Turbo Streams)
- `Message` модель уже в Phase 1
- Добавить Turbo Stream broadcast при создании Message
- Real-time чат через Action Cable

### 2.2 Dispute handling
- `Dispute` модель: job_id, raised_by_id, reason, status, resolved_at
- Новые роуты: `GET/POST /client/jobs/:id/dispute`
- Админ-интерфейс для разрешения споров

### 2.3 Shop lifecycle
- Pause: `PATCH /shop/settings` → status: paused
- Close: `DELETE /shop/settings` → status: closed
- Reopen flow

### 2.4 Public/private shop management
- Visibility toggle в shop settings
- Private shops: invitation-only доступ
- `ShopInvitation` модель (token-based, аналог существующих Invitations)

### 2.5 SEO skill pages
- `/nb/no/:skill` → SkillPagesController
- Sitemap generation
- 60 supported skills в константе

### 2.6 Member invitation management
- Shop owner приглашает фрилансера → создаётся `ShopMember` (invited)
- Фрилансер получает email → принимает (аналог существующего `/invitations/:token`)
- Новый роут: `GET /shop_member_invitations/:token` (отдельно от существующего `/invitations/:token`)

---

## Phase 3 — Позже

- Stripe Connect / card payments
- B2C клиенты
- Reviews и ratings
- Mobile apps
- Hours logging

**Никогда:** ENK/AS выплаты через Bookify — только lønn.

---

## Критические файлы для изменений

| Файл | Изменение |
|---|---|
| `config/routes.rb` | Добавить новые namespace (только добавление) |
| `app/models/user.rb` | Добавить `client`, `shop_owner` в role enum |
| `app/models/booking_line.rb` | Добавить `commission` в line_type enum |
| `app/services/pop_api_client.rb` | Добавить commission line, source_params, payee_freelance_profile_id |
| `db/migrate/` | Новые таблицы: shops, shop_members, clients, jobs, messages |

---

## Порядок реализации

1. **Migrations** — создать все таблицы
2. **Models** — Shop, ShopMember, Client, Job, Message + расширить User, BookingLine
3. **Routes** — добавить новые namespace в routes.rb
4. **Public shops** — ShopsController + views (listing + detail)
5. **Client registration** — Client::RegistrationController + BRREG
6. **Shop request flow** — ShopRequestsController + Client::RequestsController
7. **Quote flow** — Shop::QuotesController + Client::QuotesController
8. **Job completion + invoicing** — extend PopApiClient, create Booking/Payout
9. **Chat (Messages)** — JobMessagesController + Turbo Streams
10. **SEO pages** — SkillPagesController + sitemap
