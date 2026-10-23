SET search_path = hh_school;

--А1--
-- Числовой, тип integer
-- Строковый, тип text
-- Дата и время timestamp
-- Логический boolean
-- Дата и время timestamp

--А2--
-- areas - area_id
-- employers - employer_id
-- vacancies - vacancy_id
-- vacancy_details - vacancy_id --- здесь vacancy_id и первичный ключ, и внешний (к vacancies)
-- responses - response_id

--А3--
-- у нас каждое имя вакансии может встречаться по несколько раз, а особенность первичного ключа - уникальность
SELECT vacancy_name,
	count(*) AS cnt
FROM vacancies
GROUP BY vacancy_name
ORDER BY count(*) desc
LIMIT 1;
-- самая частая вакансия - Стажёр-аналитик данных, таких вакансий 6

--А4--
-- если такое сделать, то произойдет ошибка (так как базовый тип данных - число, а мы вписываем текст)
-- такое поведение СУБД спасает нас от ошибок в будущмм, так как если бы мы записали текст в salary_from, то позже столкнулись бы с проблемами
-- подсчёта числовых метрик, и были бы вынуждены  чистить базу данных

------
--Б1--
SELECT DISTINCT experience
FROM vacancies
ORDER BY experience;
-- "Нет опыта", "От 1 года до 3 лет", "От 3 до 6 лет"

SELECT DISTINCT employment
FROM vacancies
ORDER BY employment;
-- "Полная занятость", "Стажировка", "Частичная занятость"

SELECT DISTINCT professional_role
FROM vacancies
ORDER BY professional_role;
--"Аналитик данных", "Дата-инженер", "Продуктовый аналитик", "Разработчик", "Тестировщик"
-- выбросов ни в 1 случае нет, повторок тоже, NULL также отсутствует

--Б2--
SELECT vacancy_id, vacancy_name, salary_from, published_at
FROM vacancies
WHERE area_id = 1 AND closed_at IS NULL AND experience='Нет опыта' AND employment = 'Стажировка'
ORDER BY published_at DESC;
-- запрос нашёл 8 вакансий, если убрать условие про Москву, то он выведет больше вакансий (так как ушло условие на город)
-- конкретно он выведет 10 вакансий, то есть еще 4 из других городов
-- 2 запрос:
SELECT vacancy_name, professional_role, salary_from
FROM vacancies
WHERE closed_at IS NULL AND salary_from IS NOT NULL
ORDER BY salary_from DESC
LIMIT 10;
-- я немного не понял, нужно ли оставлять условия из 1 запроса в Б2, поэтому убрал ограничения на Москву и опыт

--Б3--
--Ловушка 1--
SELECT count(*) FROM vacancies WHERE closed_at = NULL;
SELECT count(*) FROM vacancies WHERE closed_at IS NULL;
--первый запрос вернул 0, а не ошибку, так как он работал так: он сравнивал значения на равенство с NULL, а изз-а особенностей NULL
--это не выдает ошибку, это выдает 0 равенств, так как ничего не равно NULL
--это хуже ошибки, так как неопытный аналитик может подумать, что NULL значений нет, что может сломать последующий анализ
--NULL в closet_at означает, что вакансия не закрыта (то есть не существует параметра о закрытии), то есть NULL=0 в первом запросе
--может ввести в заблуждение, сказав аналитику, что все вакансии закрыты


--Ловушка 2--
SELECT count(*) FROM vacancies
WHERE area_id = 1 OR area_id = 2 AND experience = 'Нет опыта';

SELECT count(*) FROM vacancies
WHERE (area_id = 1 OR area_id = 2) AND experience = 'Нет опыта';
--первый запрос читается как: "вакансии из Москвы (без разницы на опыт) или вакансии из Питера без опыта (обязательно без опыта)"
--второй запрос читается как: "вакансии из Москвы или из Питера, но обязательно без опыта (для обоих городов)"

-----
--В1--
SELECT 
    count(*) AS total_vacancies,
    count(salary_from) AS vacancies_with_salary,
    count(DISTINCT professional_role) AS total_roles,
    count(DISTINCT employer_id) AS total_employers
FROM vacancies;
--всего вакансий 52, с указанной нижней зарплатой 44, 5 направлений и 12 работодателей

SELECT 
    count(*) FILTER (WHERE closed_at IS NULL) AS open_vacancies,
    count(*) FILTER (WHERE closed_at IS NOT NULL) AS closed_vacancies,
    round(100.0 * count(*) FILTER (WHERE closed_at IS NULL) / count(*), 1) AS open_in_percent
FROM vacancies;
--всего открыто вакансий 33, а закрыто 19.Доля открытх от общего кол-ва примерно 63.5%
--count(*) = 52, показывает общее кол-во строк
--count(salary_from) = 44, показывает у скольки строк указана нижняя зп
--count(DISTINCT professional_role) = 5, показывает кол-во уникальный направлений
--Сообщение руководителю: "Из 52 вакансий сейчас открыто 33, что составляет 63.5% от общего количества, остальные 19 вакансий закрыты"

--В2--
--запрос 1--
SELECT professional_role,
	count(*) AS vacancies_cnt,
	count(DISTINCT employer_id) AS employers_cnt,
	round(avg(salary_from)) AS avg_salary_from
FROM vacancies
GROUP BY professional_role
ORDER BY vacancies_cnt DESC;

--запрос 2--
SELECT professional_role,
	count(*) AS vacancies_cnt,
	count(DISTINCT employer_id) AS employers_cnt,
	round(avg(salary_from)) AS avg_salary_from
FROM vacancies
WHERE closed_at IS NULL
GROUP BY professional_role
HAVING count(*) >= 5
ORDER BY vacancies_cnt DESC;
--больше половины рынка занимают направления аналитик данных и разработчик
--соискатель бы рассматривал вакансии аналитика данных и разработчика из-за большого кол-ва вакансий, средних нижних зарплат, кол-ва работодателей
--здесь не хватает числа откликов/спроса на конкретные вакансии, может предложение у топ-2 ролей больше  50%, но и метят туда больше людей

--условие про открытые вакансии пишется в where, потому что иначе мы сначала отсортируем без условия все показатели, что будет некорректно
--не менее 5пишется в HAVING так как это прсотой способ из уже отсортированной по условию таблицы выделить вакансии с минимум 5 позициями
--в момент выполнения WHERE база работает с сырыми строками, т.е. группы еще не сформированы и посчитать count(*) нельзя

--какая средняя нижняя граница зп среди тех открытых вакансий, где зп вообще указана?
-- не отвечает на вопрос: какова средняя вилка в целом (с учетом верхней границы salary_to

--Г1--
SELECT 
    v.vacancy_name,
    e.employer_name,
    a.area_name,
    v.salary_from
FROM vacancies v
JOIN employers e ON v.employer_id = e.employer_id
JOIN areas a ON v.area_id = a.area_id
WHERE v.salary_from IS NOT NULL
ORDER BY v.salary_from DESC
LIMIT 5;
--если написать просто area_id, то будет ошибка, так как area_id одновременно содержится в  vacancies, employers и areas,
--без псевдонима субд не может определить откуда конкретно брать значение

--Г2--
SELECT 
    e.employer_name,
    count(DISTINCT v.vacancy_id) AS vacancies_cnt,
    count(r.response_id) AS responses_cnt,
    round(1.0 * count(r.response_id) / nullif(count(DISTINCT v.vacancy_id), 0), 2) AS responses_per_vacancy
FROM employers e
LEFT JOIN vacancies v ON e.employer_id = v.employer_id
LEFT JOIN responses r ON v.vacancy_id = r.vacancy_id
GROUP BY e.employer_name
ORDER BY responses_cnt DESC;
--добавил соотношение откликов на 1 вакансию
--с LEFT JOIN 12 строк, с INNER JOIN - 11

--count(DISTINCT v.vacancy_id) необходим, так как при JOIN с таблицей откликов строки вакансий размножаются (много откликов на вакансию)
--просто count(*) посчитал бы количество строк в объединении, а не кол-во вакансий

--дополнение для ГринЭнерго--
SELECT 
    v.vacancy_name, 
    v.published_at, 
    v.closed_at, 
    v.salary_from, 
    v.salary_to, 
    v.experience,
    v.employment
FROM vacancies v
JOIN employers e ON v.employer_id = e.employer_id
WHERE e.employer_name = 'ГринЭнерго';

--в INNER JOIN исчезла компания «ГринЭнерго» (у неё нет откликов),для HR это потеря так как цель отчета — найти неактивных партнеров, 
--дополнение по ГринЭнерго: вакансия была опубликована 06.04.2026 и уже закрыта 04.05.2026, при этом в ней не был указан уровень дохода (NULL) 
--отсутствие откликов связано с отсутствием вилки зарплаты и ограниченным сроком публикации 
--предпринимать ничего не нужно, так как вакансия уже в архиве, а на будущее работодателю порекомендуем указывать зарплату для привлечения кандидатов
--а INNER JOIN прячет проблему, удаляя такие компании

--Правило выбора: LEFT JOIN: обязателен полный список из главной (левой) таблицы, даже без пары. INNER JOIN: нужны только пересечения 

--Д1--
SELECT 
    date_trunc('month', created_at)::date AS response_month,
    count(*) AS responses_cnt,
    count(*) FILTER (WHERE status = 'invited') AS invited_cnt,
    round(100.0 * count(*) FILTER (WHERE status = 'invited') / nullif(count(*), 0), 1) AS conversion_pct
FROM responses
GROUP BY 1
ORDER BY 1;

SELECT max(created_at) AS last_response_date FROM responses;
--конверсия максимальна в июне
--как будто бы вполне, много откликов и приглашений много, нельзя сказать о недостатке данных, но в любмо случае это может быть какой-то выброс
--последний месяц - август, он представлен лишь наполовину (до 15 числа), поэтому общая статистика месяца искажена

--Д2--
SELECT 
    v.professional_role,
    count(DISTINCT v.vacancy_id) AS vacancies_cnt,
    count(r.response_id) AS responses_cnt,
    count(r.response_id) FILTER (WHERE r.status = 'invited') AS invited_cnt,
    round(1.0 * count(r.response_id) / nullif(count(DISTINCT v.vacancy_id), 0), 2) AS responses_per_vacancy,
    round(100.0 * count(r.response_id) FILTER (WHERE r.status = 'invited') / nullif(count(r.response_id), 0), 1) AS conversion_pct
FROM vacancies v
LEFT JOIN responses r ON v.vacancy_id = r.vacancy_id
GROUP BY v.professional_role
ORDER BY conversion_pct DESC;
--нет, направление с макс.числом вакансий (аналитик данных) не является направлением с самой большой конверсией (тестировщик)
--я бы выбрал вакансию тестировщика, так как в ней соблюдается баланс между самой большой конверсией в приглашения и малой конкуренцией (5,57 человек на вакансию)
--Данные не учитывают качество резюме конкретного кандидата, его соответствие требованиям

--Е--
SELECT v.professional_role,
count(*) AS vacancies,
sum(v.salary_from) AS total_salary,
count(r.response_id) / count(*) AS responses_per_vacancy
FROM vacancies v
JOIN responses r ON v.vacancy_id = r.vacancy_id
WHERE v.closed_at = NULL
GROUP BY 1;
--Ошибки:
--"WHERE v.closed_at = NULL", сравнение с NULL всегда дает False, поэтому выводится 0 строк
--INNER JOIn, а не LEFT JOIN: в противном случае у нас исключаются вакансии без откликов
--"count(*) AS vacancies" из-за объединения таблиц посчитает кол-во откликов, а не вакансий
--"count(r.response_id) / count(*)" вернет рез-тат деления нацело, то есть отбросит все и вернет 0 (а еще знаменатель не защищен от деления на 0)

--правильный запрос:

WITH response_stats AS (
    SELECT 
        vacancy_id,
        count(response_id) AS responses_cnt
    FROM responses
    GROUP BY vacancy_id
)
SELECT 
    v.professional_role,
    count(DISTINCT v.vacancy_id) AS vacancies_cnt,
    round(avg(v.salary_from)) AS avg_salary_from,
    round(1.0 * coalesce(sum(r.responses_cnt), 0) / count(DISTINCT v.vacancy_id), 2) AS responses_per_vacancy
FROM vacancies v
LEFT JOIN response_stats r ON v.vacancy_id = r.vacancy_id
WHERE v.closed_at IS NULL
GROUP BY v.professional_role;

--Сумма зп в данном контексте непоказательна, она зависит от количества открытых вакансий и не отражает реальный доход специста 
--более релевантная метрика -средняя зарплата, которая показывает уровень дохода по направлению
