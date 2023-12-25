CREATE TABLE SALES_DATASET_RFM_PRJ_CLEAN AS
(
select * from SALES_DATASET_RFM_PRJ
--1
ALTER TABLE SALES_DATASET_RFM_PRJ
ALTER COLUMN ordernumber TYPE integer USING (ordernumber::integer),
ALTER COLUMN quantityordered TYPE smallint USING (quantityordered::smallint),
ALTER COLUMN priceeach TYPE numeric USING (priceeach::numeric),
ALTER COLUMN orderlinenumber TYPE smallint USING (orderlinenumber::smallint),
ALTER COLUMN sales TYPE numeric USING (sales::numeric), 
ALTER COLUMN orderdate TYPE TIMESTAMP USING (orderdate::TIMESTAMP),
ALTER COLUMN msrp TYPE smallint USING (msrp::smallint)
--2
select * from SALES_DATASET_RFM_PRJ
WHERE ordernumber is null
or quantityordered is null
or priceeach is null
or orderlinenumber is null
or sales is null
or ORDERDATE is null
--3
ALTER TABLE SALES_DATASET_RFM_PRJ
ADD COLUMN contactlastname VARCHAR

ALTER TABLE SALES_DATASET_RFM_PRJ
ADD COLUMN contactfirstname VARCHAR

UPDATE SALES_DATASET_RFM_PRJ
SET contactfirstname= UPPER(LEFT(contactfullname,1))||LOWER(SUBSTRING(contactfullname FROM 2 FOR POSITION ('-' in contactfullname)-2))
UPDATE SALES_DATASET_RFM_PRJ
SET contactlastname= UPPER(SUBSTRING(contactfullname from POSITION ('-' in contactfullname)+1 FOR 1))||LOWER(SUBSTRING(contactfullname FROM POSITION ('-' in contactfullname)+2))
--4
ALTER TABLE SALES_DATASET_RFM_PRJ
ADD COLUMN quarter_id numeric

ALTER TABLE SALES_DATASET_RFM_PRJ
ADD COLUMN month_id numeric

ALTER TABLE SALES_DATASET_RFM_PRJ
ADD COLUMN year_id numeric

UPDATE SALES_DATASET_RFM_PRJ
SET quarter_id = extract(quarter from orderdate)

UPDATE SALES_DATASET_RFM_PRJ
SET month_id = extract(month from orderdate)

UPDATE SALES_DATASET_RFM_PRJ
SET year_id = extract(year from orderdate)
--5
--su dung BOXPLOT
With cte as (SELECT
Q1-1.5*IQR as min_value,
Q3+1.5*IQR as max_value
FROM
(SELECT
percentile_cont(0.25) WITHIN GROUP (ORDER BY quantityordered) as Q1,
percentile_cont(0.75) WITHIN GROUP (ORDER BY quantityordered) as Q3,
(percentile_cont(0.75) WITHIN GROUP (ORDER BY quantityordered)-percentile_cont(0.25) WITHIN GROUP (ORDER BY quantityordered)) as IQR
from SALES_DATASET_RFM_PRJ) as a)
SELECT * from SALES_DATASET_RFM_PRJ
Where quantityordered < (select min_value from cte)
or quantityordered> (select max_value from cte)
--su dung Z-SCORE
with cte as
(SELECT orderdate,
quantityordered,
(SELECT avg(quantityordered) from SALES_DATASET_RFM_PRJ) as avg,
(SELECT stddev(quantityordered) from SALES_DATASET_RFM_PRJ) as stddev
FROM SALES_DATASET_RFM_PRJ),
cte2 as
SELECT orderdate,quantityordered,((quantityordered-avg)/stddev) as z_score
FROM cte
where abs((quantityordered-avg)/stddev)>3

--xu ly (UPDATE cac outlier thanh gia tri trung binh)
UPDATE SALES_DATASET_RFM_PRJ
SET quantityordered=(SELECT avg(quantityordered) from SALES_DATASET_RFM_PRJ)
WHERE quantityordered in (SELECT quantityordered from cte2)
)

--xu ly (DELETE)
DELETE FROM SALES_DATASET_RFM_PRJ
WHERE quantityordered in (SELECT quantityordered from cte2)
