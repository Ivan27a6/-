-- MySQL

-- Задача 1.
-- https://onecompiler.com/mysql/42fe4dxeg
-- 1. 
SELECT COUNT(DISTINCT client_id) AS 'Количество клиентов'
  FROM table_1;

/* Примечание: имя таблицы – ‘Table’ неуникально,
входит в список зарезервированных ключевых слов,
поэтому в этой задаче и впоследствии заменено на ‘table_1’.*/

-- 2.
 SELECT client_id AS 'ID клиента',
 SUM(amount) AS 'Сумма всех покупок', -- за январь 2023
 ROUND(AVG(amount), 2) AS 'Средняя сумма покупки',
 MAX(amount) AS 'Максимальный размер покупки'
   FROM table_1
WHERE transaction_date BETWEEN '2023-01-01' AND '2023-01-31' -- январь 2023
 GROUP BY client_id;

/* Примечание: имя столбца – ‘date’ неуникально,
входит в список зарезервированных ключевых слов,
поэтому в этой задаче заменено на ‘transaction_date’.*/

-- 3.
   SELECT client_id AS 'ID клиента',
   	  COUNT(*) AS 'Количество совершенных покупок'
    FROM table_1
  GROUP BY 1
HAVING COUNT(*) > 2 -- больше двух покупок
  ORDER BY 2 DESC;

-- Задача 2.
-- https://onecompiler.com/mysql/42fbahemy
-- 1. 
SELECT credit_id,
SUM(IF(status = 'EXPIRED', 1, 0))  AS 'Количество дней в просрочке'
  FROM credit
INNER JOIN credit_calculations
USING(credit_id)
WHERE YEAR(issued_date) = YEAR(NOW()) -- выданных в этом году
 GROUP BY 1;

-- 2.
-- Без оконной функции:
SELECT credit_id,
status AS 'Актуальный статус' -- с максимальной датой calculation_date
 FROM credit_calculations
             INNER JOIN (SELECT credit_id,
                     MAX(calculation_date) AS max_date
                       FROM credit_calculations
        	       GROUP BY 1) AS table_max_date
USING(credit_id)
WHERE calculation_date = max_date
 ORDER BY 1;

-- С оконной функцией:
SELECT credit_id,
status AS 'Актуальный статус' -- с максимальной датой calculation_date
 FROM (SELECT *,
MAX(calculation_date) OVER (partition BY credit_id) AS max_date
  FROM credit_calculations) AS table_max_date
WHERE calculation_date = max_date
 ORDER BY 1;
-- 3.
SELECT COUNT(credit_id) AS null_total -- Количество кредитов, по которым все статусы пустые
FROM (SELECT credit_id,
             status,
             COUNT(*) null_status
 FROM credit_calculations
             GROUP BY 1, 2
            HAVING status IS NULL) table_null_status
            INNER JOIN (SELECT credit_id,
      COUNT(*) total_status 
        FROM credit_calculations
      GROUP BY 1) table_total_status
            USING(credit_id)
WHERE null_status = total_status;

-- Задача 3.
-- https://onecompiler.com/mysql/42fe52gk2
-- 1.
SELECT COUNT(*) AS Количество /* Количество сотрудников, которые
работают в компании дольше, чем их непосредственные начальники */
  FROM (SELECT id,
hire_date AS id_hire_date,
id_chief,
chief_hire_date
  FROM employee
JOIN (SELECT id AS id_chief,
          hire_date AS chief_hire_date
            FROM employee) table_chief_hire_date
ON employee.chief_id = table_chief_hire_date.id_chief
WHERE hire_date > chief_hire_date) result_table;


-- 2.
SELECT id AS 'Дублирующиеся ID' -- Дублирующиеся строки по сотруднику
  FROM employee
INNER JOIN (SELECT id double_id,
        hire_date double_hire_date,
        chief_id double_chief_id,
        salary double_salary
           FROM employee) tb
ON employee.id = tb.double_id
WHERE id = double_id
AND (hire_date <> double_hire_date
OR chief_id <> double_chief_id
OR salary <> double_salary)
GROUP BY 1
ORDER BY 1;

-- Задача 4.
-- https://onecompiler.com/mysql/42fhn3rwh


/* Примечание: в столбце ‘currency’ данной таблицы ‘currency’ в 3 строке - ' EURO '
присутствуют нежелательные символы пробела ‘ ’,
поэтому предварительно обновим данные столбцы таблиц с помощью функции  TRIM(). */


UPDATE transactions 
SET currency = TRIM(currency);

UPDATE exchange_rate 
SET currency = TRIM(currency);


-- 1.
SELECT client_id, -- ID клиента
SUM(IF(value IS NOT NULL, amount*value, amount)) AS rub_amount -- стоимость всех покупок
  FROM transactions
LEFT JOIN exchange_rate
ON transactions.currency = exchange_rate.currency
       AND transaction_date = currency_date
GROUP BY 1
ORDER BY 1;

/* Примечание: имя таблицы – ‘currency’ неуникально, перекликается с именем столбцов данных таблиц, поэтому в этой задаче и впоследствии заменено на ‘exchange_rate.
Примечание: столбцы ‘id’ в обоих таблицах несвязаны напрямую, поэтому по ссылке заменены на tr_id и ex_id в таблицах transactions и exchange_rate. */

-- 2.
SELECT client_id, -- ID клиента
SUM(IF(value IS NOT NULL, amount*value, amount)) AS rub_amount -- стоимость всех покупок
  FROM transactions
LEFT JOIN exchange_rate
ON transactions.currency = exchange_rate.currency
LEFT JOIN (SELECT transaction_date,
     MAX(currency_date) max_cur_date
       FROM transactions
     LEFT JOIN exchange_rate
     ON transactions.currency = exchange_rate.currency
            AND currency_date <= transaction_date
    GROUP BY 1) tb_max_cur_date
USING(transaction_date)
WHERE currency_date = max_cur_date
OR transactions.currency = 'RUB'
GROUP BY 1
ORDER BY 1;
