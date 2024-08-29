CREATE OR REPLACE FUNCTION log_user_settings_changes()
RETURNS TRIGGER AS $$
BEGIN
    -- Username change
    IF (NEW.username IS DISTINCT FROM OLD.username) THEN
        INSERT INTO user_settings_logs(user_id, date_of_change, description)
        VALUES (OLD.user_id, CURRENT_TIMESTAMP, 'Username changed from ' || OLD.username || ' to ' || NEW.username);
    END IF;

    -- Password change
    IF (NEW.password IS DISTINCT FROM OLD.password) THEN
        INSERT INTO user_settings_logs(user_id, date_of_change, description)
        VALUES (OLD.user_id, CURRENT_TIMESTAMP, 'Password changed');
    END IF;

    -- Email change
    IF (NEW.email IS DISTINCT FROM OLD.email) THEN
        INSERT INTO user_settings_logs(user_id, date_of_change, description)
        VALUES (OLD.user_id, CURRENT_TIMESTAMP, 'Email changed from ' || OLD.email || ' to ' || NEW.email);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE TRIGGER user_settings_trigger
AFTER UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION log_user_settings_changes();
