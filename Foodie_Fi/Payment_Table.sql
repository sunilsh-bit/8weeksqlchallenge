Use SqlChallenge_8Week;

Create Table c3_foodie_fi.payments(
	customer_id int,
	plan_id int,
	plan_name varchar(50),
	payment_date date,
	amount float,
	payment_order int
);

insert into c3_foodie_fi.payments values(1,1,'basic monthly','2020-08-08',9.90,1),
(1,1,'basic monthly','2020-09-08',9.90,2),
(1,1,'basic monthly','2020-10-08',9.90,3),
(1,1,'basic monthly','2020-11-08',9.90,4),
(1,1,'basic monthly','2020-12-08',9.90,5),
(2,3,'pro annual','2020-09-27',199.00,1),
(13,1,'basic monthly','2020-12-22',9.90,1),
(15,2,'pro monthly','2020-03-24',19.90,1),
(15,2,'pro monthly','2020-04-24',19.90,2),
(16,1,'basic monthly','2020-06-07',9.90,1),
(16,1,'basic monthly','2020-07-07',9.90,2),
(16,1,'basic monthly','2020-08-07',9.90,3),
(16,1,'basic monthly','2020-09-07',9.90,4),
(16,1,'basic monthly','2020-10-07',9.90,5),
(16,3,'pro annual','2020-10-21',189.10,6),
(18,2,'pro monthly','2020-07-13',19.90,1),
(18,2,'pro monthly','2020-08-13',19.90,2),
(18,2,'pro monthly','2020-09-13',19.90,3),
(18,2,'pro monthly','2020-10-13',19.90,4),
(18,2,'pro monthly','2020-11-13',19.90,5),
(18,2,'pro monthly','2020-12-13',19.90,6),
(19,2,'pro monthly','2020-06-29',19.90,1),
(19,2,'pro monthly','2020-07-29',19.90,2),
(19,3,'pro annual','2020-08-29',199.00,3);