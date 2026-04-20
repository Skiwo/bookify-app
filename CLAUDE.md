# Bookify — CLAUDE.md

## Что такое Bookify
Норвежский маркетплейс для найма фрилансеров (bookify.app).
Владелец: Skiwo AS. Отдельный проект, отдельный репо.

## Биллинг через Payout Partner
Bookify **не обрабатывает платежи сам**. Всё идёт через
Payout Partner (POP) — отдельный Rails-сервис.

- Prod API: `https://core.payoutpartner.com/api/v2/partner`
- Staging:  `https://rc.core.payoutpartner.com/api/v2/partner`
- Auth: `Authorization: Bearer <API_KEY>`
- Docs: `docs/api-guide.md`

## Bookify как партнёр на POP
Bookify = один partner account на POP с `partner_api_v2 = true`.
- Shop owner = freelancer, enrolled на этот account
- Member = другой freelancer, enrolled на тот же account
- Job = один Invoice с двумя строками

## Ключевой API-флоу
1. `POST /connect_tokens` → JWT → редирект фрилансера на POP онбординг
2. После онбординга POP колбэчит: `callback_url?worker_id=X&status=approved`
3. `POST /payouts` с двумя строками:
   ```json
   {
     "worker_id": "member-id",
     "source_params": { "job_id": "...", "shop_id": "..." },
     "lines": [
       { "line_type": "work", "rate": 9500, "description": "Job work" },
       { "line_type": "commission", "rate": 500,
         "payee_freelance_profile_id": "shop-owner-profile-uuid",
         "description": "Shop commission 5%" }
     ]
   }

Три поля добавленные в POP для Bookify
Invoice.source_params — { job_id, shop_id, booking_id, source }
InvoiceLine.payee_freelance_profile_id — для commission строки
InvoiceLine.line_type = "commission" — новый тип, считается как зарплата
Правила разработки
Все изменения на отдельных роутах — не трогать существующие
Lønn only — никакого ENK/AS в Bookify
Минимальный job: 600 NOK
Shop owner комиссия: 5%
POP fee: 4.9%, employer tax: 14.1%

Референсы
docs/bookify-plan-presentation.html — полная презентация продукта
docs/how-it-works.md — как POP работает
docs/api-guide.md — API reference
docs/norwegian-payroll.md — расчёт налогов