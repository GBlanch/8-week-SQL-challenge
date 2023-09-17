DROP SCHEMA IF EXISTS data_bank;
CREATE SCHEMA data_bank;

SET search_path = data_bank;

DROP TABLE IF EXISTS regions ;
CREATE TABLE regions (
					  region_id INTEGER,
					  region_name VARCHAR(16)
					);

INSERT INTO regions
  (region_id, region_name)
  
VALUES
  ('1', 'Australia'),
  ('2', 'America'),
  ('3', 'Africa'),
  ('4', 'Asia'),
  ('5', 'Europe');
