CREATE TABLE vistor_log (firstname text, favoritecolor text, created_at timestamp);

INSERT INTO visitor_log (firstname, favoritecolor, created_at) VALUES ($(firstname), $(favoritecolor), $(created_at));