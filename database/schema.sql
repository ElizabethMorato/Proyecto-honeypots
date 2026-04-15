CREATE TABLE eventos (
  id SERIAL PRIMARY KEY,
  timestamp TIMESTAMP,
  src_ip VARCHAR(50),
  username VARCHAR(100),
  password VARCHAR(100),
  command TEXT,
  hash VARCHAR(255),
  client_version VARCHAR(255),
  session VARCHAR(100)
);