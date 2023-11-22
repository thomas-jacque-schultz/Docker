
CREATE DATABASE schub_utilisateur;

CREATE USER poplab WITH PASSWORD 'azertyuiop';

GRANT ALL PRIVILEGES ON DATABASE "schub_utilisateur" to poplab;


-- Keycloak
CREATE DATABASE keycloak;

CREATE USER keycloak WITH PASSWORD 'keycloak1234';

GRANT ALL PRIVILEGES ON DATABASE "keycloak" to keycloak;
