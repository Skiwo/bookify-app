# Bookify × POP — Integration Plan

## Контекст

Bookify = **один partner account на POP**, owned by Payout Partner AS.
Все shop owner'ы и roster member'ы enrolled под этим одним аккаунтом.

Существующий код (booker/freelancer flow) использует credentials отдельных буккеров.
Для Bookify нужен системный клиент с ENV-level credentials.

---

## Что уже есть (переиспользуем)

| Компонент | Где | Что делает |
|---|---|---|
| `PopApiClient#connect_url` | `pop_api_client.rb:102` | Генерирует JWT + onboarding URL |
| `PopApiClient#get_profile` | `pop_api_client.rb:39` | Получает профиль после онбординга |
| `PopApiClient#create_payout` | `pop_api_client.rb:73` | Создаёт invoice с commission line |
| `CallbacksController#onboard` | `callbacks_controller.rb` | Полный callback flow (копируем паттерн) |
| `InvitationsController#accept` | `invitations_controller.rb` | connect_url → redirect → POP |
| `Enrollment` model | `enrollment.rb` | Хранит pop_worker_id, pop_profile_data |
| `Shop.pop_worker_id` | `shops` table | Уже есть поле |
| `Bookify::InvoicingService` | `invoicing_service.rb` | Уже вызывает create_payout |

---

## Архитектура

```
Bookify POP Account (ENV: BOOKIFY_POP_*)
    ├── Shop owner → enrolled как freelancer (получает commission)
    └── Roster member → enrolled как freelancer (получает work payout)
```

Каждый участник проходит POP onboarding **один раз**:
- BankID verification
- Skattekort
- Банковский счёт

После этого `pop_worker_id` хранится у нас и используется при каждом payout.

---

## Что нужно построить

---

### 1. Bookify POP Client Factory

**Файл:** `app/services/pop_api_client.rb`

Добавить class method:

```ruby
def self.for_bookify
  new({
    api_key:    ENV.fetch("BOOKIFY_POP_API_KEY"),
    hmac_secret: ENV.fetch("BOOKIFY_POP_HMAC_SECRET"),
    partner_id: ENV.fetch("BOOKIFY_POP_PARTNER_ID"),
    base_url:   ENV.fetch("POP_BASE_URL", "https://sandbox.core.payoutpartner.com"),
    app_url:    ENV.fetch("POP_APP_URL", "https://sandbox.app.payoutpartner.com")
  })
end
```

Добавить в `.env`:
```
BOOKIFY_POP_API_KEY=...
BOOKIFY_POP_HMAC_SECRET=...
BOOKIFY_POP_PARTNER_ID=...
```

---

### 2. Shop Owner POP Enrollment

**Когда:** после создания шопа (onboarding flow).

**Флоу:**
1. `Onboarding::ShopsController#create` — шоп создан → редирект на POP enrollment
2. `GET /bookify/onboarding/connect` → `Bookify::OnboardingController#connect`
   - Вызывает `PopApiClient.for_bookify.connect_url(worker_id: current_user.id, callback_url: ...)`
   - Редирект на POP
3. POP колбэчит: `GET /bookify/callbacks/shop_owner?worker_id=X&status=approved`
4. `Bookify::CallbacksController#shop_owner`:
   - Вызывает `PopApiClient.for_bookify.get_profile(worker_id)`
   - Сохраняет `shop.update!(pop_worker_id: worker_id)`
   - Редирект на `/shop/dashboard` с notice

**Новые роуты:**
```ruby
namespace :bookify do
  get  "onboarding/connect", to: "onboarding#connect", as: :onboarding_connect
  get  "callbacks/shop_owner", to: "callbacks#shop_owner", as: :callback_shop_owner
  get  "callbacks/member",     to: "callbacks#member",     as: :callback_member
end
```

**Новые файлы:**
- `app/controllers/bookify/onboarding_controller.rb`
- `app/controllers/bookify/callbacks_controller.rb`

---

### 3. Roster Member POP Enrollment

**Когда:** после принятия инвайта через `ShopMemberInvitationsController#accept`.

**Проблема:** сейчас `ShopMember.enrollment_id` ссылается на `Enrollment` (буккер-флоу),
но Bookify-члены должны быть enrolled под Bookify account, не под личным аккаунтом владельца.

**Решение:** добавить `bookify_pop_worker_id` на `shop_members`:

```ruby
# Migration
add_column :shop_members, :bookify_pop_worker_id, :string
add_column :shop_members, :bookify_onboarding_status, :string, default: "pending"
# values: pending / onboarding / active
```

**Флоу:**
1. `ShopMemberInvitationsController#accept` → вместо `status: :active` → редирект на POP enrollment
2. `GET /bookify/member_onboarding/:token` → `Bookify::OnboardingController#member`
   - Находит ShopMember по `invitation_token`
   - `PopApiClient.for_bookify.connect_url(worker_id: shop_member.id, callback_url: ...)`
   - Редирект на POP
3. POP колбэчит: `GET /bookify/callbacks/member?worker_id=X&status=approved&token=...`
4. `Bookify::CallbacksController#member`:
   - Вызывает `get_profile(worker_id)`
   - `shop_member.update!(bookify_pop_worker_id: worker_id, status: :active, bookify_onboarding_status: "active")`
   - Редирект на shop page

---

### 4. InvoicingService — использовать Bookify client

**Файл:** `app/services/bookify/invoicing_service.rb`

Изменить:
```ruby
# Было:
def pop_client
  @pop_client ||= PopApiClient.for_user(@job.shop.owner)
end

# Станет:
def pop_client
  @pop_client ||= PopApiClient.for_bookify
end
```

`worker_id` берём из `ShopMember.bookify_pop_worker_id` (вместо `enrollment.pop_worker_id`).

---

### 5. Guard: не давать issue_quote без POP enrollment

В `ShopAdmin::JobsController#issue_quote` и `Bookify::InvoicingService#validate!`:
- Проверить что `shop.pop_worker_id.present?` (shop owner enrolled)
- Проверить что `job.assigned_member.bookify_pop_worker_id.present?` (member enrolled)

---

## Порядок реализации

1. **ENV + `PopApiClient.for_bookify`** — основа всего
2. **Shop owner enrollment** — `Bookify::OnboardingController` + `Bookify::CallbacksController#shop_owner`
3. **Member enrollment migration** — добавить `bookify_pop_worker_id` на `shop_members`
4. **Member enrollment flow** — обновить `ShopMemberInvitationsController#accept` + `Bookify::CallbacksController#member`
5. **InvoicingService** — переключить на `for_bookify` + `bookify_pop_worker_id`
6. **Guards** — защитить issue_quote и invoicing от незаенролленных

---

## Что НЕ меняем

- Существующий `/booker/*` и `/freelancer/*` flow — не трогаем
- `CallbacksController` (старый) — не трогаем, всё Bookify-специфичное в `Bookify::CallbacksController`
- Enrollment модель — не трогаем (используется буккерами)
